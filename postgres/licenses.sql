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
-- Name: licenses; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.licenses (
    uid bigint NOT NULL,
    callsign character varying(10),
    suffix character varying(7) NOT NULL,
    prefix character varying(3) NOT NULL,
    name_address character varying(200),
    issue character varying(30),
    created_at timestamp with time zone DEFAULT now(),
    internal character varying(3000),
    class integer
);


ALTER TABLE public.licenses OWNER TO dz;

--
-- Name: COLUMN licenses.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.uid IS 'UID';


--
-- Name: COLUMN licenses.callsign; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.callsign IS 'Callsign in upper case letters';


--
-- Name: COLUMN licenses.suffix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.suffix IS 'Suffix of callsign (eg. AAA)';


--
-- Name: COLUMN licenses.prefix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.prefix IS 'Prefix of callsign, e.g. OE1';


--
-- Name: COLUMN licenses.name_address; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.name_address IS 'Name and address of licencee';


--
-- Name: COLUMN licenses.issue; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.issue IS 'Issue of register (e.g. 2021-09)';


--
-- Name: COLUMN licenses.created_at; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.created_at IS 'Timestamp of insert';


--
-- Name: COLUMN licenses.internal; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.internal IS 'Internal note';


--
-- Name: COLUMN licenses.class; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.licenses.class IS 'Lic classe (e.g. 1)';


--
-- Name: licenses_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.licenses_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.licenses_uid_seq OWNER TO dz;

--
-- Name: licenses_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.licenses_uid_seq OWNED BY public.licenses.uid;


--
-- Name: licenses uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.licenses ALTER COLUMN uid SET DEFAULT nextval('public.licenses_uid_seq'::regclass);


--
-- Name: licenses_callsign_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX licenses_callsign_idx ON public.licenses USING btree (callsign);


--
-- Name: licenses_suffix_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX licenses_suffix_idx ON public.licenses USING btree (suffix);


--
-- Name: licenses_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX licenses_uid_idx ON public.licenses USING btree (uid);


--
-- PostgreSQL database dump complete
--

