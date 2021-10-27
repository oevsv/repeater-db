--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-0+deb11u1)
-- Dumped by pg_dump version 13.4 (Debian 13.4-0+deb11u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: trx; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.trx (
    uid bigint NOT NULL,
    type_of_station character varying(50) DEFAULT 'repeater_voice'::character varying NOT NULL,
    frequency_tx double precision,
    frequency_rx double precision,
    callsign character varying(10),
    antenna_heigth double precision,
    site_name character varying(100),
    sysop character varying(10),
    url character varying(500),
    hardware character varying(100),
    mmdvm boolean,
    solar_power boolean,
    battery_power boolean,
    status character varying,
    fm boolean,
    fm_wakeup character varying(50),
    ctcss_tx double precision,
    ctcss_rx double precision,
    echolink boolean,
    echolink_id bigint,
    digital_id bigint,
    dmr boolean,
    ipsc2 boolean,
    brandmeister boolean,
    network_registered boolean,
    c4fm boolean,
    c4fm_groups character varying(30),
    dstar boolean,
    dstar_rpt1 character varying(1),
    dstar_rpt2 character varying(1),
    tetra boolean,
    other_mode boolean,
    other_mode_name character varying(50),
    comment character varying(1000),
    internal character varying(3000),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.trx OWNER TO dz;

--
-- Name: TABLE trx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON TABLE public.trx IS 'All OE repeater, including packet radio and beacons (and other stuff using spectrum in the relevant bands, eg. transponders)';


--
-- Name: COLUMN trx.frequency_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.frequency_tx IS 'in MHz';


--
-- Name: COLUMN trx.frequency_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.frequency_rx IS 'in MHz';


--
-- Name: COLUMN trx.callsign; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.callsign IS 'Callsign with all characters in upper case without SSID';


--
-- Name: COLUMN trx.antenna_heigth; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.antenna_heigth IS 'heigth about ground in m';


--
-- Name: COLUMN trx.site_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.site_name IS 'Name of location, should fully identify station without city';


--
-- Name: COLUMN trx.sysop; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.sysop IS 'Callsign of sysop/keeper of station; might not be legally responsible for station';


--
-- Name: COLUMN trx.url; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.url IS 'URL including https://-Prefix of station, should be deep link';


--
-- Name: COLUMN trx.hardware; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.hardware IS 'Hardware of station';


--
-- Name: COLUMN trx.mmdvm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.mmdvm IS 'True if station is based on MMDVM-concept';


--
-- Name: COLUMN trx.solar_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.solar_power IS 'True if solar powered station';


--
-- Name: COLUMN trx.battery_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.battery_power IS 'True if battery powered station';


--
-- Name: COLUMN trx.status; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.status IS 'Status of operation: planed, active, inactive';


--
-- Name: COLUMN trx.fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.fm IS 'Analogue FM station';


--
-- Name: COLUMN trx.fm_wakeup; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.fm_wakeup IS 'Tone or DTMF needed for activation of repeater, eg. "1750 Hz" or "DTMF 1"; Subtone is not relevant here';


--
-- Name: COLUMN trx.ctcss_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.ctcss_tx IS 'CTCSS tone send by transmitter in Hz; NULL if no tone ';


--
-- Name: COLUMN trx.ctcss_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.ctcss_rx IS 'CTCSS tone required by receiver in Hz; NULL if no tone needed';


--
-- Name: COLUMN trx.echolink; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.echolink IS 'True if connected to Echolink';


--
-- Name: COLUMN trx.echolink_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.echolink_id IS 'Numeric ID in Echolink system';


--
-- Name: COLUMN trx.digital_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.digital_id IS 'Digital (DMR) ID of station, eg. 23205 or private ID eg. 932832';


--
-- Name: COLUMN trx.dmr; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dmr IS 'True if station supports DMR mode';


--
-- Name: COLUMN trx.ipsc2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.ipsc2 IS 'True if station is connected to IPSC2';


--
-- Name: COLUMN trx.brandmeister; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.brandmeister IS 'True if stations is connected to Brandmeister';


--
-- Name: COLUMN trx.network_registered; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.network_registered IS 'True if station is registered on digital network (including FM stations)';


--
-- Name: COLUMN trx.c4fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.c4fm IS 'True if C4FM is supported';


--
-- Name: COLUMN trx.c4fm_groups; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.c4fm_groups IS 'Comma separated list of C4FM groups';


--
-- Name: COLUMN trx.dstar; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dstar IS 'True if Dstar is supported';


--
-- Name: COLUMN trx.dstar_rpt1; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dstar_rpt1 IS 'Dstar Repeater 1 - Upper case character, eg. A';


--
-- Name: COLUMN trx.dstar_rpt2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dstar_rpt2 IS 'Dstar Repeater 2 - Upper case character, eg. A';


--
-- Name: COLUMN trx.tetra; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.tetra IS 'True if Tetra station';


--
-- Name: COLUMN trx.other_mode; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.other_mode IS 'True if other mode (digital or analogue)';


--
-- Name: COLUMN trx.other_mode_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.other_mode_name IS 'Short description of the other mode (eg SSB USB)';


--
-- Name: COLUMN trx.comment; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.comment IS 'Public visible comment';


--
-- Name: COLUMN trx.internal; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.internal IS 'Internal comment (for administrative perposes)';


--
-- Name: COLUMN trx.created_at; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.created_at IS 'Timestamp of insert';


--
-- Name: repeater_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.repeater_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.repeater_uid_seq OWNER TO dz;

--
-- Name: repeater_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.repeater_uid_seq OWNED BY public.trx.uid;


--
-- Name: trx uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.trx ALTER COLUMN uid SET DEFAULT nextval('public.repeater_uid_seq'::regclass);


--
-- Data for Name: trx; Type: TABLE DATA; Schema: public; Owner: dz
--

COPY public.trx (uid, type_of_station, frequency_tx, frequency_rx, callsign, antenna_heigth, site_name, sysop, url, hardware, mmdvm, solar_power, battery_power, status, fm, fm_wakeup, ctcss_tx, ctcss_rx, echolink, echolink_id, digital_id, dmr, ipsc2, brandmeister, network_registered, c4fm, c4fm_groups, dstar, dstar_rpt1, dstar_rpt2, tetra, other_mode, other_mode_name, comment, internal, created_at) FROM stdin;
2300	packet_radio	144.8	144.8	OE3XNR	\N	Nebelstein	OE3DZW	https://oe3xnr.xax.at/	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-16 14:40:51.350258+02
2301	repeater_voice	438.6125	431.0125	OE3XNR	\N	Nebelstein	OE3GWU	https://www.oe3xnr.eu/	Hytera	\N	\N	\N	active	\N	\N	88.5	\N	\N	\N	232305	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2283	beacon	5760.855	\N	OE8XGQ	\N	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2287	beacon	10368.875	\N	OE5XBM	\N	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2290	beacon	24048.875	\N	OE5XBM	\N	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2294	beacon	47088.875	\N	OE5XBM	\N	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2272	beacon	50.058	\N	OE3XLB	\N	Hohe Wand	OE3GWC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2302	packet_radio	438.225	430.625	OE3XNR	\N	Nebelstein	OE3GWU	https://www.oe3xnr.eu/	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FM Vara	Winlink	\N	2021-10-16 14:40:51.350258+02
2275	beacon	50.438	\N	OE5XHE	\N	Sternstein	OE5ANL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2282	beacon	1296.975	\N	OE5XHE	\N	Sternstein	OE5ANL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2277	beacon	144.479	\N	OE3XTR	\N	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2271	beacon	28.188	\N	OE3XAC	\N	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2273	beacon	50.066	\N	OE3XAC	\N	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2289	beacon	10368.93	\N	OE3XAC	\N	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2234	packet_radio	438.2	438.2	OE5XFR	\N	Frankenmarkt	OE5RPP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	2021-10-21 12:45:40.647422+02
2183	repeater_voice	438.55	430.95	OE7XTT	\N	Penkenjoch	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2163	repeater_voice	439.025	431.425	OE7XFJ	\N	Harschbichl	OE7GBJ	\N	\N	\N	\N	\N	active	t	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2170	repeater_voice	438.5	430.9	OE7XLH	\N	Iselsberg-Stronach	OE7JTK	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2177	repeater_voice	438.875	431.275	OE7XOI	\N	Schönjöchl	OE7SJJ	\N	\N	\N	t	\N	active	t	Tone 1750	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2263	packet_radio	\N	\N	OE1XAB	\N	Eisvogelgasse	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Mailbox	\N	2021-10-21 12:45:40.647422+02
2128	repeater_voice	438.6	431	OE6XAG	\N	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2073	repeater_voice	438.225	430.625	OE3XNK	\N	Hohe Wand	OE3GBB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2150	repeater_voice	438.525	430.925	OE6XME	\N	Kindberg Ort	OE6JFG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2040	repeater_voice	438.95	431.35	OE1XUU	\N	Kahlenberg	OE1BAD	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2044	repeater_voice	145.65	145.05	OE2XHL	\N	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2046	repeater_voice	145.7625	145.1625	OE2XJL	\N	Gernkogel	OE2HFO	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2091	repeater_voice	438.275	430.675	OE3XVI	\N	Unterberg	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2169	repeater_voice	438.4	430.8	OE7XKT	\N	Kaltenbach	OE7SBH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2285	beacon	10368.814	\N	OE8XXQ	\N	Dobratsch	OE8URQ	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2250	packet_radio	438.55	438.55	OE3XPA	\N	Kaiserkogel	OE3CJB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps/FSK 9k6bps	\N	\N	2021-10-21 12:45:40.647422+02
2034	repeater_voice	2401.9	2449.9	OE1XKU	\N	Satzberg	OE1MCU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2292	beacon	24048.965	\N	OE8XGQ	\N	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2043	repeater_voice	51.85	51.25	OE2XHL	\N	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	t	\N	\N	183.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	inactive	2021-10-16 14:40:51.350258+02
2069	repeater_voice	438.2	430.6	OE3XKV	\N	Hochkar	OE3CDW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2107	repeater_voice	438.425	430.825	OE5XDN	\N	Senftenbach/Wolfau	OE5RLN	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2042	repeater_voice	438.525	430.925	OE2XGR	\N	Gernkogel	OE2HFO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2299	repeater_voice	51.9	51.3	OE3XWJ	38	Jauerling	OE1KBC	\N	Yaesu FT8900/BARIX	\N	\N	\N	active	t	\N	162.2	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2070	repeater_voice	29.66	29.56	OE3XLU	\N	Gießhübel	OE3KLU	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trail	2021-10-16 14:40:51.350258+02
2099	repeater_voice	438.3625	430.7625	OE4XSB	\N	Hornstein/Sonnenberg	OE4JHW	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed	2021-10-16 14:40:51.350258+02
2095	repeater_voice	1298.6	1270600	OE3XWW	\N	Mönichkirchen Ort	OE3RPU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	A	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2030	repeater_voice	145.625	145.025	OE1XFW	\N	Laaerberg	OE3NSC	\N	\N	\N	\N	t	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2131	repeater_voice	438.9125	431.3125	OE6XBF	\N	Stradner Kogel	OE6JWD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2134	repeater_voice	438.925	431.325	OE6XBG	\N	Rennfeld	OE6MKD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2047	repeater_voice	145.6125	145.0125	OE2XNL	\N	Speiereck	OE2TRM	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2031	repeater_voice	438.65	431.05	OE1XFW	\N	Laaerberg	OE3NSC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2038	repeater_voice	430.4875	430.4875	OE1XTW	\N	Arsenal Funkturm	OE1ERR	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2045	repeater_voice	438.825	431.225	OE2XHM	\N	Hochköngi Matrashaus	OE2WCL	\N	\N	\N	t	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2167	repeater_voice	438.5	430.9	OE7XKH	\N	Krahberg	OE7ERJ	\N	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2118	repeater_voice	438.5	430.9	OE5XKL	\N	Krippenstein	OE5VFM	\N	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2231	repeater_voice	438.2	430.6	OE9XVJ	\N	Pfänder	OE9HLH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2203	repeater_voice	438.8375	431.2375	OE8XKK	\N	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2067	repeater_voice	1298.05	1270050	OE3XIA	\N	Exelberg	OE1AOA	\N	\N	\N	\N	\N	inactive	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2209	repeater_voice	438.425	430.825	OE8XMK	\N	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2098	repeater_voice	438.375	430.775	OE3XYR	\N	Weiterner Straße/HTL	OE3SUW	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	t	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trial	2021-10-16 14:40:51.350258+02
2175	repeater_voice	438.575	430.975	OE7XLI	\N	Hochstein	OE7JTK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2092	repeater_voice	438.425	430.825	OE3XWJ	\N	Jauerling	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2121	repeater_voice	438.65	431.05	OE5XLL	\N	Lichtenberg	OE5RNL	\N	\N	\N	\N	\N	inactive	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trial	2021-10-16 14:40:51.350258+02
2241	packet_radio	438.475	430.875	OE5XBL	\N	St. Johann am Walde	OE5HPM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox	\N	2021-10-21 12:45:40.647422+02
2235	packet_radio	\N	\N	OE7XVR	\N	Valluga	OE7ERJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-21 12:45:40.647422+02
2064	repeater_voice	438.975	431.375	OE3XFW	\N	Jochgrabenberg	OE3ARC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2060	repeater_voice	439.05	431.45	OE3XEB	\N	Troppberg	OE1NHU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2172	repeater_voice	438.3	430.7	OE7XLI	\N	Hochstein	OE7NGI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2225	repeater_voice	145.7	145.1	OE9XMV	\N	Frastanz	OE9VVV	\N	\N	\N	\N	\N	historic	t	\N	\N	123	\N	\N	\N	\N	t	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2088	repeater_voice	438.775	431.175	OE3XSA	\N	Sandl	OE3WLS	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2211	repeater_voice	145.65	145.05	OE8XOK	\N	Goldeck	OE8HAK	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2247	packet_radio	438.325	430.725	OE7XLR	\N	Seegrube	OE7FMH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	Mailbox	\N	2021-10-21 12:45:40.647422+02
2248	packet_radio	433.675	433.675	OE3XBR	\N	Troppberg	OE1NHU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2237	packet_radio	144.825	144.825	OE1XAR	\N	Bisamberg	OE1NHU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2239	packet_radio	144.95	144.95	OE3XOR	\N	Hainfelder Hütte	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2243	packet_radio	144.875	144.875	OE7XPR	\N	Sechszeiger	OE7HNT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2249	packet_radio	433.675	433.675	OE3XOR	\N	Hainfelder Hütte	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2086	repeater_voice	145.7	145.1	OE3XSA	\N	Sandl	OE3WLS	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	LV3 says sysop OE3MCU	2021-10-16 14:40:51.350258+02
2138	repeater_voice	438.9	431.3	OE6XDE	\N	Plabutsch	OE6THH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2193	repeater_voice	438.975	431.375	OE7XZT	\N	Ahorn	OE7BKH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2036	repeater_voice	438.825	431.225	OE1XQU	\N	Wienerberg	OE1MCU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2035	repeater_voice	145.75	145.15	OE3XQA	\N	Exelberg	OE1BAD	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	LV3 says callsign OE3XCA, no such license	2021-10-16 14:40:51.350258+02
2068	repeater_voice	438.5	430.9	OE3XKC	\N	Fronberg	OE3ICU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2221	repeater_voice	438.65	431.05	OE9XDV	\N	Bazora	OE9VVV	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2276	beacon	144.455	\N	OE3XAC	\N	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2280	beacon	1296.8	\N	OE3XAC	\N	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2281	beacon	1296.903	\N	OE3XTR	\N	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2298	beacon	10368.9	\N	OE3XTR	\N	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2136	repeater_voice	438.775	431.175	OE6XCG	\N	Grambach Ort	OE6TYG	\N	\N	\N	\N	t	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2274	beacon	50.405	\N	OE7XBI	\N	Rangger Köpl	OE7NCI	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW FSK 300 Hz	\N	\N	2021-10-23 20:40:08.807978+02
2295	beacon	76032.865	\N	OE1XGA	\N	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2061	repeater_voice	145.7875	145.1875	OE3XES	\N	Frauenstaffel	OE3KMA	\N	\N	\N	t	\N	active	t	\N	\N	79.7	t	185200	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2056	repeater_voice	1298.2	1270200	OE3X..	\N	Sandl	OE3WLS	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2125	repeater_voice	145.775	145.175	OE5XUL	\N	Geiersberg	OE5MLL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2062	repeater_voice	439.025	431.425	OE3XEU	\N	Frauenstaffel	OE3KMA	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2063	repeater_voice	1298.225	1270225	OE3XFC	\N	Hochwechsel	OE4KMU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2081	repeater_voice	438.7	431.1	OE3XPC	\N	Hinteralm Traisnerhütte	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	\N	\N	\N	active	t	\N	\N	162.2	t	\N	\N	t	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	cjb confirmed	2021-10-16 14:40:51.350258+02
2021	repeater_voice	438.5	430.9	OE1XAR	\N	Bisamberg	OE3NSC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2020	repeater_voice	430.4125	430.4125	OE1XAR	\N	Bisamberg	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2127	repeater_voice	145.6	145	OE6XAG	\N	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	t	\N	\N	103.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2037	repeater_voice	438.25	430.65	OE1XTK	\N	Hadersdorf	OE1TKS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2142	repeater_voice	145.7	145.1	OE6XDG	\N	Klosterneuburgerhütte	OE6POD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2184	repeater_voice	438.625	431.025	OE7XUT	\N	St. Ulrich am Pillersee Ort	OE7MFI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2297	beacon	122250.815	\N	OE1XGA	\N	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2286	beacon	10368.857	\N	OE8XGQ	\N	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2052	repeater_voice	51.89	51.29	OE2XZR	\N	Gaisberg	OE2AIP	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed	2021-10-16 14:40:51.350258+02
2100	repeater_voice	438.725	431.125	OE4XSB	\N	Hornstein/Sonnenberg	OE4JHW	\N	\N	t	\N	t	active	t	\N	\N	97.4	\N	\N	\N	t	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2082	repeater_voice	1298.5	1270500	OE3XPC	\N	Hinteralm Traisnerhütte	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	\N	\N	\N	inactive	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2194	repeater_voice	1298.2	1270.2	OE8X..	\N	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2226	repeater_voice	438.55	430.95	OE9XMV	\N	Frastanz	OE9VVV	\N	\N	\N	\N	\N	historic	t	\N	\N	123	\N	\N	\N	\N	t	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2050	repeater_voice	439.0875	431.4875	OE2XSV	\N	Hoher Sonnblick	OE7JTK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2066	repeater_voice	438.75	431.15	OE3XHW	\N	Hohe Wand	OE3GWC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2085	repeater_voice	438.9	431.3	OE3XRB	\N	Sonnenberg	OE3JWB	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2089	repeater_voice	438.925	431.325	OE3XSU	\N	Rittmannsberg 	OE5FXN	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2119	repeater_voice	145.6	145	OE5XLL	\N	Lichtenberg	OE5RNL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trail	2021-10-16 14:40:51.350258+02
2084	repeater_voice	438.55	430.95	OE3XRB	\N	Sonnenberg	OE3NRS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2256	packet_radio	\N	\N	OE1XLR	\N	Eisvogelgasse	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		\N	2021-10-21 12:45:40.647422+02
2117	repeater_voice	145.7125	145.1125	OE5XKL	\N	Krippenstein	OE5VFM	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2110	repeater_voice	145.75	145.15	OE5XGL	\N	Grünberg	OE5RDL	\N	\N	\N	\N	\N	active	t	\N	123	123	t	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2122	repeater_voice	438.2875	430.6875	OE5XOL	\N	Breitenstein	OE5PON	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	32,95	\N	\N	\N	\N	\N	\N	\N	conf	2021-10-16 14:40:51.350258+02
2224	repeater_voice	438.525	430.925	OE9XFV	\N	Gebhartsberg	OE9AFV	\N	\N	\N	\N	\N	active	t	\N	\N	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	APCO P25	\N	\N	2021-10-16 14:40:51.350258+02
2120	repeater_voice	438.475	430.875	OE5XLL	\N	Lichtenberg	OE5RNL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02
2109	repeater_voice	432.9	145.225	OE5XFN	\N	Pointen/Wasserbehälter	OE5DZL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2113	repeater_voice	438.75	431.15	OE5XHO	\N	Damberg	OE5VLL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2029	repeater_voice	439	431.4	OE1XFU	\N	Satzberg	OE1FFS	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2080	repeater_voice	438.45	430.85	OE3XPA	\N	Kaiserkogel	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	t	B	G	\N	\N	\N	\N	cjb confirmed	2021-10-16 14:40:51.350258+02
2077	repeater_voice	438.325	430.725	OE3XNR	\N	Nebelstein	OE3FPA	https://www.oe3xnr.eu/	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2126	repeater_voice	51.85	51.25	OE5XYP	\N	Steyr Stadt	OE5VLLF	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	inactive	2021-10-16 14:40:51.350258+02
2108	repeater_voice	438.95	431.35	OE5XDO	\N	Pfarrkirchen Ort	OE5MKP	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2087	repeater_voice	438.35	430.75	OE3XSA	\N	Sandl	OE3WLS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2240	packet_radio	144.8	144.8	OE2XZR	\N	Gaisberg	OE2WAO	https://oe2.oevsv.at/funkbetrieb/oe2xzr/	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-21 12:45:40.647422+02
2055	repeater_voice	439	431.4	OE2XZR	\N	Gaisberg	OE2AIP	https://oe2.oevsv.at/funkbetrieb/oe2xzr/	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	QRG 438.900 LV2 page	2021-10-16 14:40:51.350258+02
2103	repeater_voice	51.81	51.21	OE5SIX	\N	Braunau Stadt	OE5DXL	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2214	repeater_voice	438.7	431.1	OE8XPK	\N	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2160	repeater_voice	438.4	430.8	OE7XCJ	\N	Stadt/Brixner Straße	OE7AAI	\N	\N	t	\N	\N	active	t	\N	\N	\N	\N	\N	\N	t	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2219	repeater_voice	1298.575	1270575	OE9X..	\N	Pfänder	OE9HLH	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2032	repeater_voice	438.2125	430.6125	OE1XFV	\N	Ottakring	\N	http://oe1xfv.ddns.net:8080/	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2233	repeater_voice	439.05	431.45	OE9XXI	\N	Dornbirn Stadt	OE9VVV	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2096	repeater_voice	438.575	430.975	OE3XWW	\N	Mönichkirchen Ort	OE3RPU	\N	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2023	repeater_voice	1298.25	1270250	OE1XQU	\N	Wienerberg	OE1MCU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2157	repeater_voice	439.05	431.45	OE7XBI	\N	Rangger Köpl	OE7WSH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02
2215	repeater_voice	439.0875	431.4875	OE8XPK	\N	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2083	repeater_voice	438.675	431.075	OE3XQA	\N	Exelberg	OE1BAD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2022	repeater_voice	438.475	430.875	OE1XAT	\N	Hermannskogel	OE1KBC	\N	\N	\N	\N	t	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2059	repeater_voice	438.85	431.25	OE3XDA	\N	Hochkogelberg	OE3JWC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2102	repeater_voice	438.55	430.95	OE4XUB	\N	Brentenriegel	OE4KZU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2111	repeater_voice	438.8	431.2	OE5XGL	\N	Grünberg	OE5EUL	\N	\N	t	\N	\N	active	t	\N	123	123	\N	\N	\N	t	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2075	repeater_voice	145.6375	145.0375	OE3XNR	\N	Nebelstein	OE3IGW	https://www.oe3xnr.eu/	\N	\N	\N	t	active	t	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2076	repeater_voice	438.875	431.275	OE3XNR	\N	Nebelstein	OE3IGW	https://www.oe3xnr.eu/	\N	\N	\N	\N	active	t	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	t	32	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2074	repeater_voice	438.3	430.7	OE3XNK	\N	Hohe Wand	OE3GBB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2051	repeater_voice	438.975	431.375	OE2XWR	\N	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2024	repeater_voice	1298.65	1270650	OE1XDS	\N	Stadt/AKH	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	A	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2216	repeater_voice	438.55	430.95	OE8XVK	\N	Stadt/LKH	OE8WUR	\N	\N	\N	\N	\N	active	t	\N	88.5	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2049	repeater_voice	438.9	431.3	OE2XPR	\N	Haunsberg	OE2WAO	\N	\N	\N	\N	\N	historic	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	not listed on LV2 page	2021-10-16 14:40:51.350258+02
2112	repeater_voice	438.2625	430.6625	OE5XGL	\N	Grünberg	OE5RDL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2186	repeater_voice	145.6625	145.0625	OE7XWH	\N	Grünberg bei Silz	OE7MST	\N	\N	\N	t	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2220	repeater_voice	438.25	430.65	OE9XDV	\N	Bazora	OE9VVV	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2227	repeater_voice	145.65	145.05	OE9XVI	\N	Vorderälpele	OE9HMV	\N	\N	\N	\N	\N	historic	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	ATV info 18h30/19h	2021-10-16 14:40:51.350258+02
2104	repeater_voice	438.3	430.7	OE5XBN	\N	Braunau Ort	OE5MCM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2206	repeater_voice	145.625	145.025	OE8XMK	\N	Magdalensberg	OE8HJK	\N	\N	\N	\N	t	active	t	\N	88.5	88.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2222	repeater_voice	145.575	144.975	OE9XDV	\N	Bazora	OE9VVV	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2027	repeater_voice	145.575	144.975	OE1XDS	\N	Stadt/AKH	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2140	repeater_voice	145.6375	145.0375	OE6XDF	\N	Dobl	OE6THH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2116	repeater_voice	439.0625	431.4625	OE5XIM	\N	Sternstein	OE5KPN	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2190	repeater_voice	145.675	145.075	OE7XZH	\N	Bruckerberg	OE7FMI	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2171	repeater_voice	145.7	145.1	OE7XLI	\N	Hochstein	OE7JTK	\N	\N	\N	t	\N	active	t	Tone 1750	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2115	repeater_voice	438.975	431.375	OE5XIM	\N	Sternstein	OE5KPN	\N	\N	\N	\N	\N	active	t	\N	123	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2123	repeater_voice	438.575	430.975	OE5XOL	\N	Breitenstein	OE5PON	\N	\N	\N	\N	\N	active	t	\N	123	123	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	conf	2021-10-16 14:40:51.350258+02
2106	repeater_voice	438.725	431.125	OE5XDM	\N	Hunerkogel	OE5MLL	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2188	repeater_voice	438.6	431	OE7XWT	\N	Weinbergerhaus	OE7MPI	\N	\N	\N	\N	\N	active	t	\N	\N	77	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2192	repeater_voice	145.575	432.575	OE7XZR	\N	Zugspitze Ö	OE7DA	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2195	repeater_voice	438.65	431.05	OE8XCK	\N	Rossegger Str/LWZ	OE8RGQ	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2204	repeater_voice	438.3	430.7	OE8XKP	\N	Klippitztörl	OE1BAD	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2242	packet_radio	144.925	144.925	OE7XHR	\N	Axams / Hoadl	OE7MBT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2124	repeater_voice	438.525	430.925	OE5XOL	\N	Breitenstein	OE5PON	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	conf	2021-10-16 14:40:51.350258+02
2197	repeater_voice	438.9	431.3	OE8XFK	\N	Dobratsch	OE8URQ	\N	\N	\N	t	t	active	t	\N	88.5	88.5	\N	\N	232895	t	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2079	repeater_voice	145.65	145.05	OE3XPA	\N	Kaiserkogel	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	\N	\N	\N	active	t	\N	\N	\N	t	341109	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	cjb confirmed	2021-10-16 14:40:51.350258+02
2101	repeater_voice	145.775	145.175	OE4XUB	\N	Brentenriegel	OE4KZU	\N	\N	\N	\N	t	active	t	\N	\N	\N	t	156782	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling OE3XCR-OE4XUB	2021-10-16 14:40:51.350258+02
2026	repeater_voice	438.525	430.925	OE1XDS	\N	Stadt/AKH	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2057	repeater_voice	438.725	431.125	OE3XAV	\N	Kleinhardersdorf Ort	OE3PKB	\N	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2303	repeater_voice	145.65	145.05	OE8XDK	\N	Goldeck	OE8OWK	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2093	repeater_voice	438.6	431	OE3XWJ	\N	Jauerling	OE1KBC	\N	\N	\N	\N	\N	active	t	\N	162.2	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2305	repeater_voice	438.575	430.975	OE8XMK	\N	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	t	\N	88.5	88.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2306	beacon	10368.814	\N	OE8XGQ	\N	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2307	packet_radio	438.125	430.525	OE2XZR	\N	Gaisberg	OE2WAO	https://oe2.oevsv.at/funkbetrieb/oe2xzr/	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox,Winlink	\N	2021-10-21 12:45:40.647422+02
2308	repeater_voice	1298.375	1270.375	OE2XZR	\N	Gaisberg	OE2AIP	https://oe2.oevsv.at/funkbetrieb/oe2xzr/	\N	\N	\N	\N	active	t	\N	\N	\N	\N	304806	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2309	packet_radio	144.8	144.8	OE2XGR	\N	Gernkogel	OE2WIO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-21 12:45:40.647422+02
2310	packet_radio	144.8	144.8	OE2XWR	\N	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-21 12:45:40.647422+02
2311	packet_radio	144.8	144.8	OE2XHR	\N	Hochköngi Matrashaus	OE2WCL	\N	\N	\N	t	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-16 14:40:51.350258+02
2312	packet_radio	144.8	144.8	OE2XPR	\N	Haunsberg	OE2WAO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-16 14:40:51.350258+02
2090	repeater_voice	438.4	430.8	OE3XTR	\N	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2058	repeater_voice	438.85	431.25	OE3XCR	\N	Hutwisch	OE4KZU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02
2094	repeater_voice	439.075	431.475	OE3XWU	\N	Hochwechsel	OE4RLC	\N	\N	t	\N	\N	active	t	\N	\N	\N	\N	\N	\N	t	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	? /4KMU	2021-10-16 14:40:51.350258+02
2262	packet_radio	438	438	OE9XRK	\N	Feldkirch	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	Winlink	\N	2021-10-21 12:45:40.647422+02
2313	packet_radio	10.145	10.145	OE3XEC	\N	Ostarrichi Kaserne	OE3FQU	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	USB PT1-2 Ardop 500	Winlink	\N	2021-10-27 00:31:20.45889+02
2314	packet_radio	3607	10.145	OE3XEC	\N	Ostarrichi Kaserne	OE3FQU	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	USB Pactor 1-4/VaraHF	Winlink	\N	2021-10-27 00:31:20.47017+02
2315	packet_radio	3616	10.145	OE3XEC	\N	Ostarrichi Kaserne	OE3FQU	https://www.oe3xec.at/wp/	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	USB Pactor 1-4/VaraHF	Winlink	\N	2021-10-27 00:31:20.481413+02
2114	repeater_voice	438.25	430.65	OE5XIM	\N	Sternstein	OE5KPN	\N	\N	t	\N	t	active	\N	\N	\N	\N	\N	\N	\N	t	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2105	repeater_voice	438.775	431.175	OE5XBR	\N	Stadt/Froschberg	OE5AJP	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2191	repeater_voice	438.45	430.85	OE7XZH	\N	Bruckerberg	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2269	packet_radio	144.8	144.8	OE1XDU	\N	Wieden/Gußhausstraße	OE1RSA	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-23 18:38:59.606853+02
2187	repeater_voice	438.5	430.9	OE7XWJ	\N	Stilluppklamm	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2270	packet_radio	433.625	433.625	OE1XDU	\N	Wieden/Gußhausstraße	OE1RSA	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-23 18:38:59.606853+02
2196	repeater_voice	439	431.4	OE8XDK	\N	Goldeck	OE8OWK	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2207	repeater_voice	438.225	430.625	OE8XMK	\N	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2199	repeater_voice	438.45	430.85	OE8XGK	\N	Finkenstein/Neumüllern	OE8VIK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	232836	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2208	repeater_voice	438.85	431.25	OE8XMK	\N	Magdalensberg	OE8HJK	\N	Hytera RD965	\N	\N	t	active	\N	\N	\N	\N	\N	\N	232802	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2198	repeater_voice	1298.1	1270.1	OE8XFK	\N	Dobratsch	OE8URQ	\N	\N	\N	\N	\N	historic	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2200	repeater_voice	145.5875	144.9875	OE8XKK	\N	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	historic	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2135	repeater_voice	438.625	431.025	OE6XCD	\N	Stuhleck	OE3KLU	\N	\N	\N	\N	t	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2129	repeater_voice	438.875	431.275	OE6XAG	\N	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2137	repeater_voice	1298.2	1270200	OE6XDD	\N	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2132	repeater_voice	438.975	431.375	OE6XBF	\N	Stradner Kogel	OE6TYG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2133	repeater_voice	145.65	145.05	OE6XBG	\N	Rennfeld	OE6MKD	\N	\N	\N	\N	\N	active	t	\N	\N	103.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2039	repeater_voice	438.45	430.85	OE1XUR	\N	Laaerberg Schule	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2202	repeater_voice	439.075	431.475	OE8XKK	\N	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2205	repeater_voice	439.05	431.45	OE8XKQ	\N	Gerlitzen	OE8PKR	\N	\N	\N	\N	\N	active	t	\N	88.5	88.5	t	921900	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2071	repeater_voice	145.5875	144.9875	OE3XLU	\N	Gießhübel	OE3KLU	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2189	repeater_voice	438.2	430.6	OE7XXR	\N	Rofan Roßkogel	OE7SRI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2212	repeater_voice	145.7375	145.1375	OE8XPK	\N	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	t	\N	88.5	88.5	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2217	repeater_voice	438.95	431.35	OE8XWK	\N	St. Georgen am Längsee Ort	OE1BAD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	232805	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2218	repeater_voice	438.775	431.175	OE8XWZ	\N	Wölfnitz Ort	OE8LCK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2229	repeater_voice	438.5	430.9	OE9XVJ	\N	Pfänder	OE9LTV	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2185	repeater_voice	145.6875	145.0875	OE7XVR	\N	Valluga	OE7ERJ	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2244	packet_radio	438.275	430.675	OE7XLR	\N	Seegrube	OE7FMH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Mailbox	\N	2021-10-21 12:45:40.647422+02
2159	repeater_voice	1259.2	1294.2	OE7XBI	\N	Rangger Köpl	OE7WSH	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02
2130	repeater_voice	438.425	430.825	OE6XAR	\N	Klosterneuburgerhütte	OE6POD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2147	repeater_voice	438.35	430.75	OE6XIG	\N	Oberaich	OE6JFG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2054	repeater_voice	438.55	430.95	OE2XZR	\N	Gaisberg	OE2RPL	https://oe2.oevsv.at/funkbetrieb/oe2xzr/	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2156	repeater_voice	51.91	51.31	OE7XBI	\N	Rangger Köpl	OE7NCI	\N	\N	\N	\N	\N	active	t	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02
2223	repeater_voice	434.9	434.9	OE9XFV	\N	Gebhartsberg	OE9AFV	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2228	repeater_voice	438.625	431.025	OE9XVI	\N	Vorderälpele	OE9PKV	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2230	repeater_voice	438.875	431.275	OE9XVJ	\N	Pfänder	OE9HLH	\N	\N	\N	\N	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2232	repeater_voice	438.825	431.225	OE9XVV	\N	Dünserberg	OE9TFH	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2143	repeater_voice	438.65	431.05	OE6XEE	\N	Stubalpe	OE6PZG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2158	repeater_voice	439.075	431.475	OE7XBI	\N	Rangger Köpl	OE7WSH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2141	repeater_voice	438.675	431.075	OE6XDG	\N	Klosterneuburgerhütte	OE6POD	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2028	repeater_voice	438.3375	430.7375	OE1XDT	\N	Donauturm	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2053	repeater_voice	145.6875	145.0875	OE2XZR	\N	Gaisberg	OE2AIP	https://oe2.oevsv.at/funkbetrieb/oe2xzr/	\N	\N	\N	t	active	t	\N	\N	88.5	t	304806	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2268	packet_radio	438.025	430.425	OE2XWR	\N	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox,Winlink,APRS	\N	2021-10-21 12:45:40.647422+02
2236	packet_radio	\N	\N	OE7XZR	\N	Zugspitze Ö	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-21 12:45:40.647422+02
2153	repeater_voice	145.675	145.075	OE6XPG	\N	Planai	OE6SFG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2148	repeater_voice	145.775	145.175	OE6XLG	\N	Stubalpe	OE6PZG	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2041	repeater_voice	430.5625	430.5625	OE1XZS	\N	Penzing/Breitenseerstraße	OE1AZS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2078	repeater_voice	438.8	431.2	OE3XNS	\N	Buschberg	OE3NSU	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2072	repeater_voice	439.025	431.425	OE3XLU	\N	Gießhübel	OE3KLU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2296	beacon	76032.875	\N	OE5XBM	\N	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2166	repeater_voice	438.05	430.45	OE7XIH	\N	Hoadl	OE7MBT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2097	repeater_voice	145.7625	145.1625	OE3XWW	\N	Mönichkirchen Ort	OE3RPU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	G	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2284	beacon	5760.893	\N	OE1XGA	\N	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2293	beacon	47088.8	\N	OE1XGA	\N	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2065	repeater_voice	145.725	145.125	OE3XHW	\N	Hohe Wand	OE3GWC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2279	beacon	432.4	\N	OE3XAC	\N	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2176	repeater_voice	438.65	431.05	OE7XLR	\N	Seegrube	OE7AAI	\N	\N	\N	\N	\N	active	t	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling Südtirol	2021-10-16 14:40:51.350258+02
2178	repeater_voice	145.7	145.1	OE7XRT	\N	Hahnenkamm	OE7WRH	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2179	repeater_voice	145.6125	145.0125	OE7XTI	\N	Patscherkofel	OE7DA	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2180	repeater_voice	145.7625	145.1625	OE7XTR	\N	Krahberg	OE7TTT	\N	\N	\N	\N	t	active	t	\N	\N	77	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2181	repeater_voice	145.75	145.15	OE7XTT	\N	Penkenjoch	OE7WWH	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2161	repeater_voice	438.9	431.3	OE7XFI	\N	Gallzein Kogelmoos	OE7WOT	\N	\N	\N	\N	t	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2155	repeater_voice	439.025	431.425	OE6XVE	\N	Stubalpe	OE6PZG	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2174	repeater_voice	439.075	431.475	OE7XLI	\N	Hochstein	OE7JTK	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2146	repeater_voice	51.93	51.33	OE6XIE	\N	Stubalpe	OE6PZG	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2162	repeater_voice	438.825	431.225	OE7XFJ	\N	Harschbichl	OE7GBJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2173	repeater_voice	438.875	431.275	OE7XLI	\N	Hochstein	OE7JTK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2288	beacon	10368.88	\N	OE1XGA	\N	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2291	beacon	24048.96	\N	OE1XGA	\N	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02
2210	repeater_voice	145.7625	145.1625	OE8XNK	\N	Gerlitzen	OE8DSK	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2213	repeater_voice	438.5	430.9	OE8XPK	\N	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	232802	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2251	packet_radio	438.1	438.1	OE5XSO	\N	Zell am Pettenfirst	OE5FHM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	\N	\N	2021-10-21 12:45:40.647422+02
2254	packet_radio	438.525	430.925	OE7XHR	\N	Axams / Hoadl	OE7MBT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	\N	\N	2021-10-21 12:45:40.647422+02
2257	packet_radio	144.925	144.925	OE9XFR	\N	Schellenberg	OE9WLJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Winlink	\N	2021-10-21 12:45:40.647422+02
2258	packet_radio	438.35	144.85	OE5XBR	\N	Linz Froschberg	OE5AJP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps		\N	2021-10-21 12:45:40.647422+02
2260	packet_radio	430.4	430.4	OE9XFR	\N	Schellenberg	OE9WLJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Winlink	\N	2021-10-21 12:45:40.647422+02
2261	packet_radio	438	438	OE9XFR	\N	Schellenberg	OE9WLJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	Winlink	\N	2021-10-21 12:45:40.647422+02
2266	packet_radio	144.85	144.85	OE5XBR	\N	Linz Froschberg	OE5AJP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Mailbox	\N	2021-10-21 12:45:40.647422+02
2264	packet_radio	\N	\N	OE6XPE	\N	Pichling	OE6PWD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Mailbox	\N	2021-10-21 12:45:40.647422+02
2253	packet_radio	438	430.4	OE7XGR	\N	Gefrorene Wand	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	\N	\N	2021-10-21 12:45:40.647422+02
2245	packet_radio	433.675	433.675	OE1XAR	\N	Bisamberg	OE1NHU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2246	packet_radio	438.125	430.525	OE1XUR	\N	Laaerberg Schule	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	\N	\N	2021-10-21 12:45:40.647422+02
2154	repeater_voice	439.1	431.5	OE6XRE	\N	Eisenerzer Reichenstein	OE6SWG	\N	\N	\N	t	t	active	t	\N	\N	103.5	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2265	packet_radio	144.9	144.9	OE5XBL	\N	St. Johann am Walde	OE5HPM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2/2k4bps	Mailbox	\N	2021-10-21 12:45:40.647422+02
2267	packet_radio	438.325	430.725	OE2XGR	\N	Gernkogel	OE2WIO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox,Winlink	\N	2021-10-21 12:45:40.647422+02
2048	repeater_voice	438.975	431.375	OE2XNM	\N	Speiereck	OE2TRM	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2164	repeater_voice	145.7875	145.1875	OE7XGI	\N	Wurmkogel Lift	OE7ABT	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2168	repeater_voice	145.775	145.175	OE7XKI	\N	Hohe Salve	OE7SLI	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2139	repeater_voice	1298.05	1270050	OE6XDF	\N	Dobl	OE6THH	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2144	repeater_voice	438.2	430.6	OE6XFD	\N	Mitteregg	OE6SSF	\N	\N	\N	\N	\N	active	t	\N	\N	103.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2145	repeater_voice	438.75	431.15	OE6XGD	\N	Ungerdorf Ort	OE6ERD	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2149	repeater_voice	438.8	431.2	OE6XMD	\N	Zirbitzkogel	OE6WVG	\N	\N	\N	t	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2151	repeater_voice	439	431.4	OE6XNG	\N	Gaberl/Wiedneralm	OE6NPG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2152	repeater_voice	439.05	431.45	OE6XPF	\N	Pichling	OE6MRG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2165	repeater_voice	438.925	431.325	OE7XGR	\N	Gefrorene Wand	OE7FMI	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2182	repeater_voice	438.35	430.75	OE7XTT	\N	Penkenjoch	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
2259	packet_radio	438.2	438.2	OE5XUL	\N	Geiersberg	OE5FHM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Winlink	\N	2021-10-21 12:45:40.647422+02
2238	packet_radio	144.725	144.725	OE2XMR	\N	Speiereck	OE2VPK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2252	packet_radio	438.475	438.475	OE6XFE	\N	St. Wolfgang Ort	OE6RKE	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02
2201	repeater_voice	438.6	431	OE8XKK	\N	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	232108	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02
\.


--
-- Name: repeater_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.repeater_uid_seq', 2315, true);


--
-- Name: trx trx_pk; Type: CONSTRAINT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.trx
    ADD CONSTRAINT trx_pk PRIMARY KEY (uid);


--
-- Name: trx_callsign_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_callsign_idx ON public.trx USING btree (callsign);


--
-- Name: trx_location_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_location_idx ON public.trx USING btree (site_name);


--
-- PostgreSQL database dump complete
--

