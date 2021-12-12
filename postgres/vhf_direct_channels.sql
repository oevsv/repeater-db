--
-- PostgreSQL database dump
--

-- Dumped from database version 13.5 (Debian 13.5-0+deb11u1)
-- Dumped by pg_dump version 13.5 (Debian 13.5-0+deb11u1)

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
-- Name: direct_channels; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.direct_channels (
    uid bigint DEFAULT nextval('public.repeater_uid_seq'::regclass) NOT NULL,
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
    created_at timestamp with time zone DEFAULT now(),
    cc integer
);


ALTER TABLE public.direct_channels OWNER TO dz;

--
-- Name: COLUMN direct_channels.frequency_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.frequency_tx IS 'in MHz';


--
-- Name: COLUMN direct_channels.frequency_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.frequency_rx IS 'in MHz';


--
-- Name: COLUMN direct_channels.callsign; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.callsign IS 'Callsign with all characters in upper case without SSID';


--
-- Name: COLUMN direct_channels.antenna_heigth; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.antenna_heigth IS 'heigth about ground in m';


--
-- Name: COLUMN direct_channels.site_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.site_name IS 'Name of location, should fully identify station without city';


--
-- Name: COLUMN direct_channels.sysop; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.sysop IS 'Callsign of sysop/keeper of station; might not be legally responsible for station';


--
-- Name: COLUMN direct_channels.url; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.url IS 'URL including https://-Prefix of station, should be deep link';


--
-- Name: COLUMN direct_channels.hardware; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.hardware IS 'Hardware of station';


--
-- Name: COLUMN direct_channels.mmdvm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.mmdvm IS 'True if station is based on MMDVM-concept';


--
-- Name: COLUMN direct_channels.solar_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.solar_power IS 'True if solar powered station';


--
-- Name: COLUMN direct_channels.battery_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.battery_power IS 'True if battery powered station';


--
-- Name: COLUMN direct_channels.status; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.status IS 'Status of operation: planed, active, inactive';


--
-- Name: COLUMN direct_channels.fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.fm IS 'Analogue FM station';


--
-- Name: COLUMN direct_channels.fm_wakeup; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.fm_wakeup IS 'Tone or DTMF needed for activation of repeater, eg. "1750 Hz" or "DTMF 1"; Subtone is not relevant here';


--
-- Name: COLUMN direct_channels.ctcss_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.ctcss_tx IS 'CTCSS tone send by transmitter in Hz; NULL if no tone ';


--
-- Name: COLUMN direct_channels.ctcss_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.ctcss_rx IS 'CTCSS tone required by receiver in Hz; NULL if no tone needed';


--
-- Name: COLUMN direct_channels.echolink; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.echolink IS 'True if connected to Echolink';


--
-- Name: COLUMN direct_channels.echolink_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.echolink_id IS 'Numeric ID in Echolink system';


--
-- Name: COLUMN direct_channels.digital_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.digital_id IS 'Digital (DMR) ID of station, eg. 23205 or private ID eg. 932832';


--
-- Name: COLUMN direct_channels.dmr; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.dmr IS 'True if station supports DMR mode';


--
-- Name: COLUMN direct_channels.ipsc2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.ipsc2 IS 'True if station is connected to IPSC2';


--
-- Name: COLUMN direct_channels.brandmeister; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.brandmeister IS 'True if stations is connected to Brandmeister';


--
-- Name: COLUMN direct_channels.network_registered; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.network_registered IS 'True if station is registered on digital network (including FM stations)';


--
-- Name: COLUMN direct_channels.c4fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.c4fm IS 'True if C4FM is supported';


--
-- Name: COLUMN direct_channels.c4fm_groups; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.c4fm_groups IS 'Comma separated list of C4FM groups';


--
-- Name: COLUMN direct_channels.dstar; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.dstar IS 'True if Dstar is supported';


--
-- Name: COLUMN direct_channels.dstar_rpt1; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.dstar_rpt1 IS 'Dstar Repeater 1 - Upper case character, eg. A';


--
-- Name: COLUMN direct_channels.dstar_rpt2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.dstar_rpt2 IS 'Dstar Repeater 2 - Upper case character, eg. A';


--
-- Name: COLUMN direct_channels.tetra; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.tetra IS 'True if Tetra station';


--
-- Name: COLUMN direct_channels.other_mode; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.other_mode IS 'True if other mode (digital or analogue)';


--
-- Name: COLUMN direct_channels.other_mode_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.other_mode_name IS 'Short description of the other mode (eg SSB USB)';


--
-- Name: COLUMN direct_channels.comment; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.comment IS 'Public visible comment';


--
-- Name: COLUMN direct_channels.internal; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.internal IS 'Internal comment (for administrative perposes)';


--
-- Name: COLUMN direct_channels.created_at; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.created_at IS 'Timestamp of insert';


--
-- Name: COLUMN direct_channels.cc; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.direct_channels.cc IS 'Color Code (default DMR code is 1)';


--
-- Data for Name: direct_channels; Type: TABLE DATA; Schema: public; Owner: dz
--

COPY public.direct_channels (uid, type_of_station, frequency_tx, frequency_rx, callsign, antenna_heigth, site_name, sysop, url, hardware, mmdvm, solar_power, battery_power, status, fm, fm_wakeup, ctcss_tx, ctcss_rx, echolink, echolink_id, digital_id, dmr, ipsc2, brandmeister, network_registered, c4fm, c4fm_groups, dstar, dstar_rpt1, dstar_rpt2, tetra, other_mode, other_mode_name, comment, internal, created_at, cc) FROM stdin;
2395	digipeater	144.8	144.8	\N	\N	APRS2 - AFSK1k2 2m	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-12-09 12:29:58.152217+01	\N
2396	digipeater	432.5	432.5	\N	\N	ARPS7 - AFSK1k2 70cm	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-12-09 12:29:58.188238+01	\N
2398	direct	433.45	433.45	\N	\N	D-70CD - Calling digital 70cm	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	t	\N	t	\N	\N	t	\N	\N	\N	\N	2021-12-09 12:29:58.260218+01	\N
2390	direct	430.125	430.125	\N	\N	D-U010 - Voice direct 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 12:19:53.360216+01	\N
2391	direct	430.15	430.15	\N	\N	D-U012 - Voice direct 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 12:19:53.384185+01	\N
2392	direct	430.175	430.175	\N	\N	D-U014 - Voice direct 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 12:19:53.411217+01	\N
2393	direct	430.2	430.2	\N	\N	D-U016 - Voice direct 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 12:19:53.435262+01	\N
2388	direct	433.5	433.5	\N	\N	D-70CF - Calling FM 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 12:17:27.266291+01	\N
2397	digipeater	438.025	438.025	\N	\N	D-POCS -  POCSAG OE	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	POCSAG	\N	\N	2021-12-09 12:29:58.220192+01	\N
2400	direct	434	434	\N	\N	D-70EM - Voice direct 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Update 11.12.21	2021-12-11 20:47:21.766602+01	\N
2399	direct	432.6	432.6	\N	\N	D-HOTS - Hotspot MMDVM	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	t	\N	t	\N	\N	t	\N	\N	\N	\N	2021-12-09 13:16:17.257231+01	\N
2385	direct	145.5	145.5	\N	\N	D-S20 - Voice direct 2m	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 09:40:51.349229+01	\N
2386	direct	145.525	145.525	\N	\N	D-S21 - Voice direct 2m	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 09:40:51.349229+01	\N
2387	direct	145.55	145.55	\N	\N	D-S22  - Voice direct 2m	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 09:40:51.349229+01	\N
2389	direct	433.1	433.1	\N	\N	D-U008 - Voice direct 70cm	\N	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-12-09 12:19:53.327186+01	\N
\.


--
-- Name: direct_channels trx_pk_1; Type: CONSTRAINT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.direct_channels
    ADD CONSTRAINT trx_pk_1 PRIMARY KEY (uid);


--
-- Name: trx_c4fm_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_c4fm_idx_1 ON public.direct_channels USING btree (c4fm);


--
-- Name: trx_callsign_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_callsign_idx_1 ON public.direct_channels USING btree (callsign);


--
-- Name: trx_dmr_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_dmr_idx_1 ON public.direct_channels USING btree (dmr);


--
-- Name: trx_dstar_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_dstar_idx_1 ON public.direct_channels USING btree (dstar);


--
-- Name: trx_fm_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_fm_idx_1 ON public.direct_channels USING btree (fm);


--
-- Name: trx_frequency_tx_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_frequency_tx_idx_1 ON public.direct_channels USING btree (frequency_tx);


--
-- Name: trx_other_mode_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_other_mode_idx_1 ON public.direct_channels USING btree (other_mode);


--
-- Name: trx_site_name_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_site_name_idx_1 ON public.direct_channels USING btree (site_name);


--
-- Name: trx_tetra_idx_1; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_tetra_idx_1 ON public.direct_channels USING btree (tetra);


--
-- PostgreSQL database dump complete
--

