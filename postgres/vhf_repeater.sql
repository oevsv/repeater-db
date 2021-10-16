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
-- Name: repeater; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.repeater (
    uid bigint NOT NULL,
    type_of_station character varying(50) DEFAULT 'repeater_voice'::character varying NOT NULL,
    frequency_tx double precision,
    frequency_rx double precision,
    bandwidth_tx double precision DEFAULT 12.5,
    polarization character varying(30) DEFAULT 'V'::character varying,
    callsign character varying(10),
    latitude double precision,
    longitude double precision,
    geom public.geometry(Geometry,4326),
    locator_short_import character varying(20),
    location_source character varying(50),
    see_level double precision,
    see_level_import double precision,
    antenna_heigth double precision,
    city character varying(100),
    location character varying(100),
    sysop character varying(10),
    url character varying(500),
    hardware character varying(100),
    mmdvm boolean,
    solar_power boolean,
    battery_power boolean,
    status character varying,
    fm boolean,
    activation character varying(50),
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


ALTER TABLE public.repeater OWNER TO dz;

--
-- Name: TABLE repeater; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON TABLE public.repeater IS 'All OE repeater, including packet radio and beacons (and other stuff using spectrum in the relevant bands, eg. transponders)';


--
-- Name: COLUMN repeater.frequency_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.frequency_tx IS 'in MHz';


--
-- Name: COLUMN repeater.frequency_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.frequency_rx IS 'in MHz';


--
-- Name: COLUMN repeater.bandwidth_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.bandwidth_tx IS 'Bandwidth of transmission in kHz';


--
-- Name: COLUMN repeater.polarization; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.polarization IS 'Main polarization of antenna: V,H,L,R';


--
-- Name: COLUMN repeater.callsign; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.callsign IS 'Callsign with all characters in upper case without SSID';


--
-- Name: COLUMN repeater.latitude; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.latitude IS 'Latitude in WGS84 projection';


--
-- Name: COLUMN repeater.longitude; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.longitude IS 'Longitude in WGS84 projection';


--
-- Name: COLUMN repeater.geom; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.geom IS 'Point geometry in EPSG 3857';


--
-- Name: COLUMN repeater.locator_short_import; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.locator_short_import IS 'Imported short locator, for comparison';


--
-- Name: COLUMN repeater.see_level; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.see_level IS 'See level im m based on WGS84 centroid';


--
-- Name: COLUMN repeater.see_level_import; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.see_level_import IS 'Imported see_level';


--
-- Name: COLUMN repeater.antenna_heigth; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.antenna_heigth IS 'heigth about ground in m';


--
-- Name: COLUMN repeater.city; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.city IS 'Next major city (to find/identify location)';


--
-- Name: COLUMN repeater.location; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.location IS 'Name of location, should fully identify station without city';


--
-- Name: COLUMN repeater.sysop; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.sysop IS 'Callsign of sysop/keeper of station; might not be legally responsible for station';


--
-- Name: COLUMN repeater.url; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.url IS 'URL including https://-Prefix of station, should be deep link';


--
-- Name: COLUMN repeater.hardware; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.hardware IS 'Hardware of station';


--
-- Name: COLUMN repeater.mmdvm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.mmdvm IS 'True if station is based on MMDVM-concept';


--
-- Name: COLUMN repeater.solar_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.solar_power IS 'True if solar powered station';


--
-- Name: COLUMN repeater.battery_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.battery_power IS 'True if battery powered station';


--
-- Name: COLUMN repeater.status; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.status IS 'Status of operation: planed, active, inactive';


--
-- Name: COLUMN repeater.fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.fm IS 'Analogue FM station';


--
-- Name: COLUMN repeater.activation; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.activation IS 'Tone or DTMF needed for activation, eg. "1750 Hz" or "DTMF 1"; Subtone is not relevant here';


--
-- Name: COLUMN repeater.ctcss_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.ctcss_tx IS 'CTCSS tone send by transmitter in Hz; NULL if no tone ';


--
-- Name: COLUMN repeater.ctcss_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.ctcss_rx IS 'CTCSS tone required by receiver in Hz; NULL if no tone needed';


--
-- Name: COLUMN repeater.echolink; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.echolink IS 'True if connected to Echolink';


--
-- Name: COLUMN repeater.echolink_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.echolink_id IS 'Numeric ID in Echolink system';


--
-- Name: COLUMN repeater.digital_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.digital_id IS 'Digital (DMR) ID of station, eg. 23205 or private ID eg. 932832';


--
-- Name: COLUMN repeater.dmr; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.dmr IS 'True if station supports DMR mode';


--
-- Name: COLUMN repeater.ipsc2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.ipsc2 IS 'True if station is connected to IPSC2';


--
-- Name: COLUMN repeater.brandmeister; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.brandmeister IS 'True if stations is connected to Brandmeister';


--
-- Name: COLUMN repeater.network_registered; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.network_registered IS 'True if station is registered on digital network (including FM stations)';


--
-- Name: COLUMN repeater.c4fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.c4fm IS 'True if C4FM is supported';


--
-- Name: COLUMN repeater.c4fm_groups; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.c4fm_groups IS 'Comma separated list of C4FM groups';


--
-- Name: COLUMN repeater.dstar; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.dstar IS 'True if Dstar is supported';


--
-- Name: COLUMN repeater.dstar_rpt1; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.dstar_rpt1 IS 'Dstar Repeater 1 - Upper case character, eg. A';


--
-- Name: COLUMN repeater.dstar_rpt2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.dstar_rpt2 IS 'Dstar Repeater 2 - Upper case character, eg. A';


--
-- Name: COLUMN repeater.tetra; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.tetra IS 'True if Tetra station';


--
-- Name: COLUMN repeater.other_mode; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.other_mode IS 'True if other mode (digital or analogue)';


--
-- Name: COLUMN repeater.other_mode_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.other_mode_name IS 'Short description of the other mode (eg SSB USB)';


--
-- Name: COLUMN repeater.comment; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.comment IS 'Public visible comment';


--
-- Name: COLUMN repeater.internal; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.internal IS 'Internal comment (for administrative perposes)';


--
-- Name: COLUMN repeater.created_at; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.created_at IS 'Timestamp of insert';


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

ALTER SEQUENCE public.repeater_uid_seq OWNED BY public.repeater.uid;


--
-- Name: repeater uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.repeater ALTER COLUMN uid SET DEFAULT nextval('public.repeater_uid_seq'::regclass);


--
-- Data for Name: repeater; Type: TABLE DATA; Schema: public; Owner: dz
--

COPY public.repeater (uid, type_of_station, frequency_tx, frequency_rx, bandwidth_tx, polarization, callsign, latitude, longitude, geom, locator_short_import, location_source, see_level, see_level_import, antenna_heigth, city, location, sysop, url, hardware, mmdvm, solar_power, battery_power, status, fm, activation, ctcss_tx, ctcss_rx, echolink, echolink_id, digital_id, dmr, ipsc2, brandmeister, network_registered, c4fm, c4fm_groups, dstar, dstar_rpt1, dstar_rpt2, tetra, other_mode, other_mode_name, comment, internal, created_at) FROM stdin;
\.


--
-- Name: repeater_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.repeater_uid_seq', 1, false);


--
-- Name: repeater repeater_pk; Type: CONSTRAINT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.repeater
    ADD CONSTRAINT repeater_pk PRIMARY KEY (uid);


--
-- Name: repeater_callsign_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX repeater_callsign_idx ON public.repeater USING btree (callsign);


--
-- Name: repeater_geom_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX repeater_geom_idx ON public.repeater USING gist (geom);


--
-- Name: repeater_location_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX repeater_location_idx ON public.repeater USING btree (location);


--
-- PostgreSQL database dump complete
--

