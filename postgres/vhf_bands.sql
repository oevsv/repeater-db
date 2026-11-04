--
-- PostgreSQL database dump
--

\restrict d58qe9rUwM2wAHcV3VzfzDV8Cs8xfMeLTB1SS8isgwWBVSe8HN4sBpdybKTY0rV

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
-- Data for Name: bands; Type: TABLE DATA; Schema: public; Owner: vhf_owner
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.bands DISABLE TRIGGER ALL;

COPY public.bands (uid, band_name, frequency_from, frequency_to, common_band) FROM stdin;
1	2200m	0.1357	0.1378	\N
2	630m	0.472	0.479	\N
3	160m	181	2	\N
4	80m	3.5	3.8	\N
5	60m	53515	5.3665	\N
6	40m	7	7.2	\N
7	30m	10.1	10.15	\N
8	20m	14	14.35	\N
9	17m	18.068	18.168	\N
11	15m	21	21.145	\N
12	12m	24.89	24.99	\N
13	10m	28	29.7	\N
14	6m	50	54	\N
15	70MHz	70	70.5	\N
19	13cm	2300	2450	\N
20	3.4GHz	3400	3475	\N
21	5GHz	5650	5850	\N
22	10GHz	10000	10500	\N
23	24GHz	24000	24250	\N
24	47GHz	47000	47200	\N
26	122GHz	122250	123000	\N
28	241GHz	241000	250000	\N
29	275GHz	275000	3000000	\N
18	23cm	1240	1300	\N
25	76GHz	75000	81500	\N
27	134GHz	134000	141000	\N
16	2m	144	146	t
17	70cm	430	440	t
\.


ALTER TABLE public.bands ENABLE TRIGGER ALL;

--
-- Name: band_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: vhf_owner
--

SELECT pg_catalog.setval('public.band_uid_seq', 28, true);


--
-- PostgreSQL database dump complete
--

\unrestrict d58qe9rUwM2wAHcV3VzfzDV8Cs8xfMeLTB1SS8isgwWBVSe8HN4sBpdybKTY0rV

