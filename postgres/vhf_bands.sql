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
-- Name: bands; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.bands (
    uid integer NOT NULL,
    band_name character varying(30),
    frequency_from double precision,
    frequency_to double precision
);


ALTER TABLE public.bands OWNER TO dz;

--
-- Name: band_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.band_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.band_uid_seq OWNER TO dz;

--
-- Name: band_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.band_uid_seq OWNED BY public.bands.uid;


--
-- Name: bands uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.bands ALTER COLUMN uid SET DEFAULT nextval('public.band_uid_seq'::regclass);


--
-- Data for Name: bands; Type: TABLE DATA; Schema: public; Owner: dz
--

COPY public.bands (uid, band_name, frequency_from, frequency_to) FROM stdin;
1	2200m	0.1357	0.1378
2	630m	0.472	0.479
3	160m	181	2
4	80m	3.5	3.8
5	60m	53515	5.3665
6	40m	7	7.2
7	30m	10.1	10.15
8	20m	14	14.35
9	17m	18.068	18.168
11	15m	21	21.145
12	12m	24.89	24.99
13	10m	28	29.7
14	6m	50	54
15	70MHz	70	70.5
19	13cm	2300	2450
20	3.4GHz	3400	3475
21	5GHz	5650	5850
22	10GHz	10000	10500
23	24GHz	24000	24250
24	47GHz	47000	47200
26	122GHz	122250	123000
28	241GHz	241000	250000
29	275GHz	275000	3000000
16	2m	144	146
17	70cm	430	440
18	23cm	1240	1300
25	76GHz	75000	81500
27	134GHz	134000	141000
\.


--
-- Name: band_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.band_uid_seq', 28, true);


--
-- Name: band_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX band_uid_idx ON public.bands USING btree (uid);


--
-- Name: TABLE bands; Type: ACL; Schema: public; Owner: dz
--

GRANT SELECT ON TABLE public.bands TO web_anon;


--
-- PostgreSQL database dump complete
--

