--
-- PostgreSQL database dump
--

\restrict ggT8sLspLGAFCR0qnr72d8hF7W5tuYBLd7ozwKnjEtEjfFqJk1eqpZUk0e8TDWq

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
-- Data for Name: setting_options; Type: TABLE DATA; Schema: public; Owner: postgres
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.setting_options DISABLE TRIGGER ALL;

COPY public.setting_options (uid, object, filter) FROM stdin;
2	settings	{"types": [{"type": null, "label": "@all", "default": true}, {"type": "fm", "label": "FM", "default": false}, {"type": "dmr", "label": "DMR", "default": false}, {"type": "c4fm", "label": "C4FM", "default": false}, {"type": "dstar", "label": "Dstar", "default": false}, {"type": "tetra", "label": "Tetra", "default": false}, {"type": "beacon", "label": "Beacon", "default": false}, {"type": "digipeater", "label": "Digipeater", "default": false}, {"type": "atv", "label": "ATV", "default": false}]}
1	settings	{"types": [{"type": null, "label": "@all", "default": true}, {"type": "fm", "label": "FM", "default": false}, {"type": "dmr", "label": "DMR", "default": false}, {"type": "c4fm", "label": "C4FM", "default": false}, {"type": "dstar", "label": "Dstar", "default": false}, {"type": "tetra", "label": "Tetra", "default": false}, {"type": "beacon", "label": "Beacon", "default": false}, {"type": "digipeater", "label": "Digipeater", "default": false}, {"type": "atv", "label": "ATV", "default": false}]}
\.


ALTER TABLE public.setting_options ENABLE TRIGGER ALL;

--
-- Name: setting_options_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.setting_options_uid_seq', 1, true);


--
-- PostgreSQL database dump complete
--

\unrestrict ggT8sLspLGAFCR0qnr72d8hF7W5tuYBLd7ozwKnjEtEjfFqJk1eqpZUk0e8TDWq

