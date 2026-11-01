--
-- PostgreSQL database dump
--

\restrict G4tW91lfkQJLEfkBKVdUaXJ5GaCReUqQPvwwNVspHit9bcplq4XzcE6tk5S4hP8

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
-- Data for Name: bl_kz_prefix; Type: TABLE DATA; Schema: public; Owner: dz
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.bl_kz_prefix DISABLE TRIGGER ALL;

COPY public.bl_kz_prefix (uid, bl_kz, prefix, manager) FROM stdin;
1	9	OE1	OE1RHC
2	5	OE2	OE2WAO
3	3	OE3	OE3CJB
4	1	OE4	OE3MPS
5	4	OE5	OE5MPL
6	6	OE6	OE6FNG
7	7	OE7	OE7TPH
8	2	OE8	OE8OWK
9	8	OE9	OE9HLH
\.


ALTER TABLE public.bl_kz_prefix ENABLE TRIGGER ALL;

--
-- Name: bl_kz_prefix_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.bl_kz_prefix_uid_seq', 9, true);


--
-- PostgreSQL database dump complete
--

\unrestrict G4tW91lfkQJLEfkBKVdUaXJ5GaCReUqQPvwwNVspHit9bcplq4XzcE6tk5S4hP8

