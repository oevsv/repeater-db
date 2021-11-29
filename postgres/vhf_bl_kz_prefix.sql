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
-- Name: bl_kz_prefix; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.bl_kz_prefix (
    uid integer NOT NULL,
    bl_kz smallint NOT NULL,
    prefix character varying(3) NOT NULL,
    manager character varying(10)
);


ALTER TABLE public.bl_kz_prefix OWNER TO dz;

--
-- Name: TABLE bl_kz_prefix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON TABLE public.bl_kz_prefix IS 'Mapping between BEV Bundesländerkennzeichen and amateur radio prefix';


--
-- Name: COLUMN bl_kz_prefix.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.bl_kz_prefix.uid IS 'UID';


--
-- Name: COLUMN bl_kz_prefix.bl_kz; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.bl_kz_prefix.bl_kz IS 'Austria regional ID according to BEV';


--
-- Name: COLUMN bl_kz_prefix.prefix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.bl_kz_prefix.prefix IS 'Prefix of Austrian amateur radio callsigns in this area';


--
-- Name: COLUMN bl_kz_prefix.manager; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.bl_kz_prefix.manager IS 'VHF-Manager of region (UKW Referent im LV)';


--
-- Name: bl_kz_prefix_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.bl_kz_prefix_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bl_kz_prefix_uid_seq OWNER TO dz;

--
-- Name: bl_kz_prefix_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.bl_kz_prefix_uid_seq OWNED BY public.bl_kz_prefix.uid;


--
-- Name: bl_kz_prefix uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.bl_kz_prefix ALTER COLUMN uid SET DEFAULT nextval('public.bl_kz_prefix_uid_seq'::regclass);


--
-- Data for Name: bl_kz_prefix; Type: TABLE DATA; Schema: public; Owner: dz
--

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


--
-- Name: bl_kz_prefix_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.bl_kz_prefix_uid_seq', 9, true);


--
-- PostgreSQL database dump complete
--

