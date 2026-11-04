--
-- PostgreSQL database dump
--

\restrict oIp3Rgl3ARAqJtRdNw33VjMoLObp988erMsPjOyKcKwpoXK24BsbcmlKmWsJ2Zo

-- Dumped from database version 15.19 (Debian 15.19-1.pgdg13+2)
-- Dumped by pg_dump version 15.19 (Debian 15.19-1.pgdg13+2)

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

--
-- Data for Name: direct_channels; Type: TABLE DATA; Schema: public; Owner: vhf_owner
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.direct_channels DISABLE TRIGGER ALL;

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


ALTER TABLE public.direct_channels ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

\unrestrict oIp3Rgl3ARAqJtRdNw33VjMoLObp988erMsPjOyKcKwpoXK24BsbcmlKmWsJ2Zo

