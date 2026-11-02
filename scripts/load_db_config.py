from configparser import ConfigParser


def load_db_config(filename='db_config.ini', section='postgresql'):
    """
    Load database configuration from an .ini file.
    Returns a dictionary of connection parameters for psycopg.connect().
    """
    # example 'db_config.ini' (libpq parameter names)
    # [postgresql]
    # host = /var/run/postgresql      (socket directory, or a host name / address)
    # port = 5432
    # dbname = vhf
    # user = add-user-here
    # password = add-password-here    (not needed for peer authentication on the socket)

    parser = ConfigParser()
    if not parser.read(filename):
        raise Exception(f"Database config {filename} not found or not readable.")

    if not parser.has_section(section):
        raise Exception(f"Section {section} not found in the {filename} file.")

    db_config = dict(parser.items(section))
    # psycopg2 also accepted "database"; libpq / psycopg 3 only know "dbname".
    if 'database' in db_config:
        db_config.setdefault('dbname', db_config.pop('database'))
    return db_config
