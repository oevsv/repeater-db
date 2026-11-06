#!/usr/bin/python3
"""E-mail notifications for tickets (website /ticket).

For every new ticket message (the first text and every reply) one mail goes to
the ticket's author (users.email, from the SSO login) and to the VHF management
(ADMIN, in Cc). Sent through the local mail server (SMTP on localhost:25).
Messages with ticket_message.mailed NULL are sent, then marked; the database
announces new ones with NOTIFY ticket_mail (migration 2026-11-06_03_ticket_mail.sql),
and they are checked every 5 minutes anyway (also retries after a temporary
failure, e.g. mail server down). A message that can't be sent at all (rejected
permanently, SMTP 5xx) is logged as "GAVE UP" and skipped, so it never blocks
the others.

    python3 ticket_mail.py            # service: runs until stopped
    python3 ticket_mail.py --once     # send what is pending, then exit
    python3 ticket_mail.py --dry-run  # print the pending mails, send / mark nothing

Database: libpq defaults and environment (PGHOST, PGDATABASE, ...), the service
logs in as repeater_mail over the local socket (peer authentication).
Environment (optional):
    TICKET_SITE_URL   link base, default https://repeater.oevsv.at/de
    TICKET_MAIL_FROM  sender, default "ÖVSV Repeater <noreply@repeater.oevsv.at>"
    TICKET_SMTP_HOST  default localhost
    TICKET_SMTP_PORT  default 25
"""

import os
import re
import smtplib
import sys
from email.message import EmailMessage
from email.utils import formatdate, make_msgid

import psycopg
from psycopg.rows import dict_row

ADMIN = 'ukw@oevsv.at'
SITE_URL = os.environ.get('TICKET_SITE_URL', 'https://repeater.oevsv.at/de').rstrip('/')
MAIL_FROM = os.environ.get('TICKET_MAIL_FROM', 'ÖVSV Repeater <noreply@repeater.oevsv.at>')
SMTP_HOST = os.environ.get('TICKET_SMTP_HOST', 'localhost')
SMTP_PORT = int(os.environ.get('TICKET_SMTP_PORT', '25'))
POLL_SECONDS = 300

STATUS = {'open': 'Offen', 'answered': 'Beantwortet', 'closed': 'Erledigt'}
EMAIL_RE = re.compile(r'^[^@\s<>,;"]+@[^@\s<>,;"]+\.[^@\s<>,;"]+$')

# The oldest unsent message, locked so that a second instance skips it.
PENDING = """
SELECT m.id, m.body, m.staff, m.created,
       NOT EXISTS (SELECT FROM public.ticket_message p
                    WHERE p.ticket_id = m.ticket_id AND p.created < m.created) AS first,
       t.id AS ticket_id, t.heading, t.status, t.site_name,
       a.callsign AS author_callsign, a.email AS author_email,
       w.callsign AS writer_callsign
  FROM public.ticket_message m
  JOIN public.ticket t ON t.id = m.ticket_id
  JOIN public.users a ON a.id = t.user_id
  JOIN public.users w ON w.id = m.user_id
 WHERE m.mailed IS NULL
 ORDER BY m.created
 LIMIT 1
   FOR UPDATE OF m SKIP LOCKED
"""


def one_line(text):
    """Header-safe: no line breaks, collapsed whitespace."""
    return ' '.join((text or '').split())


def build_mail(r):
    """The notification for one message (row of PENDING)."""
    heading = one_line(r['heading'])
    writer = one_line(r['writer_callsign']) or '?'
    if r['first']:
        what, subject = f'Neue Meldung von {writer}', f'Neue Meldung: {heading}'
    elif r['staff']:
        what, subject = f'Antwort vom UKW-Referat ({writer})', f'Antwort: {heading}'
    else:
        what, subject = f'Antwort von {writer}', f'Antwort: {heading}'
    url = f"{SITE_URL}/ticket/{r['ticket_id']}"

    lines = [what, '', f'Betreff:  {heading}']
    if r['site_name']:
        lines.append(f"Standort: {one_line(r['site_name'])}")
    lines += [f"Status:   {STATUS.get(r['status'], r['status'])}", '',
              r['body'].replace('\r\n', '\n'), '',
              f'Ansehen und antworten: {url}', '',
              '-- ',
              'ÖVSV Repeater - automatische Nachricht. Bitte auf der Seite antworten.',
              'Automatic message: please reply on the page.']

    msg = EmailMessage()
    msg['From'] = MAIL_FROM
    author = (r['author_email'] or '').strip()
    if author and EMAIL_RE.match(author) and author.lower() != ADMIN:
        msg['To'] = author
        msg['Cc'] = ADMIN
    else:
        msg['To'] = ADMIN  # no (valid) address of the author
    msg['Reply-To'] = ADMIN
    msg['Subject'] = f'[Repeater] {subject}'
    msg['Date'] = formatdate(localtime=True)
    msg['Message-ID'] = make_msgid(domain='repeater.oevsv.at')
    # Same thread in the mail program for all mails of a ticket.
    thread = f"<ticket-{r['ticket_id']}@repeater.oevsv.at>"
    msg['In-Reply-To'] = thread
    msg['References'] = thread
    msg['Auto-Submitted'] = 'auto-generated'
    msg.set_content('\n'.join(lines))
    return msg


def permanent(e):
    """A send error that will not go away by retrying (SMTP 5xx). Connection
    problems and 4xx (mail server down, busy) are temporary."""
    if isinstance(e, smtplib.SMTPRecipientsRefused):
        return all(code >= 500 for code, _ in e.recipients.values())
    if isinstance(e, (smtplib.SMTPConnectError, smtplib.SMTPHeloError)):
        return False  # the mail server as a whole, not this message
    if isinstance(e, smtplib.SMTPResponseException):
        return e.smtp_code >= 500
    return False


def send_pending(conn):
    """Sends the unsent messages one by one; returns how many.

    A message that cannot be sent at all (the mail can't be built, or the mail
    server rejects it permanently) is logged as GAVE UP and marked as mailed,
    so it never blocks the messages after it. A temporary failure (mail server
    down) leaves it unsent and stops this round: retried at the next check."""
    sent = 0
    while True:
        with conn.transaction():
            with conn.cursor(row_factory=dict_row) as cur:
                r = cur.execute(PENDING).fetchone()
                if r is None:
                    return sent
                where = f"message {r['id']} (ticket {r['ticket_id']})"
                try:
                    msg = build_mail(r)
                    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30) as smtp:
                        refused = smtp.send_message(msg)
                except (OSError, smtplib.SMTPException) as e:
                    if not permanent(e):
                        print(f"FAILED {where}, retried later: {e!r}", file=sys.stderr, flush=True)
                        return sent
                    print(f"GAVE UP {where}: {e!r}", file=sys.stderr, flush=True)
                except Exception as e:  # building the mail: retrying won't help
                    print(f"GAVE UP {where}: {e!r}", file=sys.stderr, flush=True)
                else:
                    print(f"sent {where} to {msg['To']}" + (f", cc {msg['Cc']}" if msg['Cc'] else '')
                          + (f"; refused: {refused}" if refused else ''), flush=True)
                    sent += 1
                cur.execute('UPDATE public.ticket_message SET mailed = now() WHERE id = %s', (r['id'],))


def main(args):
    dry_run = '--dry-run' in args
    once = '--once' in args or dry_run
    with psycopg.connect(autocommit=True) as conn:
        if dry_run:
            # Show all pending mails without marking them: nothing is committed.
            with conn.transaction(force_rollback=True):
                with conn.cursor(row_factory=dict_row) as cur:
                    for r in cur.execute(PENDING.replace('LIMIT 1', '').replace('FOR UPDATE OF m SKIP LOCKED', '')):
                        print(build_mail(r).as_string(), '\n' + '=' * 70, flush=True)
            return 0
        conn.execute('LISTEN ticket_mail')
        while True:
            send_pending(conn)
            if once:
                return 0
            # Wait for a new message (NOTIFY) or the next check.
            for _ in conn.notifies(timeout=POLL_SECONDS, stop_after=1):
                pass


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
