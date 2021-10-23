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
    geom public.geometry(Geometry,3857),
    locator_short_import character varying(20),
    location_source character varying(500),
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
    created_at timestamp with time zone DEFAULT now(),
    "Order" integer,
    loc_import character varying(100),
    dummy character varying,
    geo_prefix character varying(3)
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
-- Name: COLUMN repeater.geo_prefix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.repeater.geo_prefix IS 'Austrian amateur callsign prefix derived from geo coordinates';


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

COPY public.repeater (uid, type_of_station, frequency_tx, frequency_rx, bandwidth_tx, polarization, callsign, latitude, longitude, geom, locator_short_import, location_source, see_level, see_level_import, antenna_heigth, city, location, sysop, url, hardware, mmdvm, solar_power, battery_power, status, fm, activation, ctcss_tx, ctcss_rx, echolink, echolink_id, digital_id, dmr, ipsc2, brandmeister, network_registered, c4fm, c4fm_groups, dstar, dstar_rpt1, dstar_rpt2, tetra, other_mode, other_mode_name, comment, internal, created_at, "Order", loc_import, dummy, geo_prefix) FROM stdin;
2275	beacon	50.438	\N	12.5	V	OE5XHE	48.5599155	14.2690062	0101000020110F0000DD761A81C23C3841901775E030A75741	JN78DN	OSM	1105.1	1130	\N	Bad Leonfelden	Sternstein	OE5ANL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Sternstein bei Bad Leonfelden	\N	OE5
2282	beacon	1296.975	\N	12.5	V	OE5XHE	48.5599155	14.2690062	0101000020110F0000DD761A81C23C3841901775E030A75741	JN78DN	OSM	1105.1	1130	\N	Bad Leonfelden	Sternstein	OE5ANL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Sternstein bei Bad Leonfelden	\N	OE5
2277	beacon	144.479	\N	12.5	V	OE3XTR	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	Google Maps	917.8	1015	\N	Wr. Neustadt	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Hohe Wand	\N	OE3
2287	beacon	10368.875	\N	12.5	V	OE5XBM	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ29	\N	955.3	985	\N	Linz	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Breitenstein	\N	OE5
2290	beacon	24048.875	\N	12.5	V	OE5XBM	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ29	\N	955.3	985	\N	Linz	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Breitenstein	\N	OE5
2294	beacon	47088.875	\N	12.5	V	OE5XBM	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ29	\N	955.3	985	\N	Linz	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Breitenstein	\N	OE5
2283	beacon	5760.855	\N	12.5	V	OE8XGQ	46.695	13.914167	0101000020110F0000338339FC75A2374154537DE8537A5641	JN66WQ	\N	1908.7	1909	\N	Villach	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Gerlitze	\N	OE8
2272	beacon	50.058	\N	12.5	V	OE3XLB	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	\N	917.8	1092	\N	Wr. Neustadt	Hohe Wand	OE3GWC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Hohe Wand, Kleine Kanzel	\N	OE3
2271	beacon	28.188	\N	12.5	V	OE3XAC	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	724	\N	St. Pölten	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Kaiserkogel	\N	OE3
2273	beacon	50.066	\N	12.5	V	OE3XAC	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	722	\N	St. Pölten	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Kaiserkogel	\N	OE3
2289	beacon	10368.93	\N	12.5	V	OE3XAC	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	724	\N	St. Pölten	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Kaiserkogel	\N	OE3
2295	beacon	76032.865	\N	12.5	V	OE1XGA	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG06	\N	483.4	480	\N	Wien	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Wien, Kahlenberg	\N	OE1
2297	beacon	122250.815	\N	12.5	V	OE1XGA	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG06	\N	483.4	480	\N	Wien	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Wien, Kahlenberg	\N	OE1
2276	beacon	144.455	\N	12.5	V	OE3XAC	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	722	\N	St. Pölten	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Kaiserkogel	\N	OE3
2033	repeater_voice	1298.1	1270.1	12.5	V	OE1XGW	48.17535	16.45889	0101000020110F0000F382FA4003F53B419618FF2343685741	JN88EF	Rougth estimate, Google Maps	157	360	\N	Wien	Simmering Heizturm (geplant geweisen)	OE1WRS	\N	\N	\N	\N	\N	historic	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	15	WIEN SIMMERING	dumb2	OE1
2280	beacon	1296.8	\N	12.5	V	OE3XAC	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	724	\N	St. Pölten	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Kaiserkogel	\N	OE3
2281	beacon	1296.903	\N	12.5	V	OE3XTR	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	Google Maps	917.8	1015	\N	Wr. Neustadt	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Hohe Wand	\N	OE3
2298	beacon	10368.9	\N	12.5	V	OE3XTR	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	Google Maps	917.8	1015	\N	Wr. Neustadt	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Hohe Wand	\N	OE3
2136	repeater_voice	438.775	431.175	12.5	V	OE6XCG	47.00617	15.4962	0101000020110F000006F8DD1765523A4155FFD24ECAAB5641	JN77RA	Google Maps , Erlenstraße 35	336.8	345	\N	Graz	Grambach Ort	OE6TYG	\N	\N	\N	\N	t	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	118	GRAZ	dumb2	OE6
2274	beacon	50.405	\N	12.5	V	OE7XBI	47.242985	11.181174	0101000020110F0000ED599D980AFE32413142477FA0D15641	JN57OF	https://hamnetdb.net/?m=site&q=oe7xbi&as=-All-	1938	1946	\N	Oberpferfuss	Rangger Köpl	OE7NCI	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW FSK 300 Hz	\N	\N	2021-10-23 20:40:08.807978+02	\N	Ranggerköpfl	\N	OE7
2286	beacon	10368.857	\N	12.5	V	OE8XGQ	46.695	13.914167	0101000020110F0000338339FC75A2374154537DE8537A5641	JN66WQ	\N	1908.7	1909	\N	Villach	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Gerlitze	\N	OE8
2292	beacon	24048.965	\N	12.5	V	OE8XGQ	46.695	13.914167	0101000020110F0000338339FC75A2374154537DE8537A5641	JN66WQ	\N	1908.7	1909	\N	Villach	Gerlitzen	OE8PGQ	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Gerlitze	\N	OE8
2285	beacon	10368.814	\N	12.5	V	OE8XXQ	46.603397	13.670989	0101000020110F0000101EBC88B73837412A541C3CD26B5641	JN66UO	\N	2159	2166	\N	Villach	Dobratsch	OE8URQ	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Dobratsch	\N	OE8
2234	packet_radio	438.2	438.2	12.5	V	OE5XFR	\N	\N	\N	JN67RX	\N	\N	\N	\N	\N	Frankenmarkt	OE5RPP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	2021-10-21 12:45:40.647422+02	\N	Frankenmarkt	\N	\N
2070	repeater_voice	29.66	29.56	12.5	V	OE3XLU	48.09671	16.23893	0101000020110F0000E72D2B6B5D953B41DFC18DC2735B5741	JN88CC	Google Maps, Waldgasse 1	398.2	424	\N	Mödling	Gießhübel	OE3KLU	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trail	2021-10-16 14:40:51.350258+02	52	MÖDLING GIESZHÜBL	dumb2	OE3
2099	repeater_voice	438.3625	430.7625	12.5	V	OE4XSB	47.875253	16.470265	0101000020110F0000C1F35583F5F93B415C057F9A7B375741	JN87FV	https://www.bergfex.at/sommer/burgenland/touren/wanderung/29623,hornstein-rundwanderung-zum-sonnenberg/	438.7	471	\N	Eisenstadt	Hornstein/Sonnenberg	OE4JHW	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed	2021-10-16 14:40:51.350258+02	81	HORNSTEIN SONNENBERG	dumb2	OE4
2098	repeater_voice	438.375	430.775	12.5	V	OE3XYR	48.22104	15.62219	0101000020110F0000C05A623C2E893A41AF2725C7B66F5741	JN78TE	https://hamnetdb.net/?m=site&q=oe3xyr&as=-All-	291.4	285	\N	St. Pölten	Weiterner Straße/HTL	OE3SUW	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trial	2021-10-16 14:40:51.350258+02	80	ST.PÖLTEN HTL	dumb2	OE3
2067	repeater_voice	1298.05	1270050	12.5	V	OE3XIA	48.24876033	16.2440474	0101000020110F000039E4C11597973B41C415E6FA3C745741	JN88CF	https://www.peakbagger.com/peak.aspx?pid=-87298	514.8	577	\N	Wien	Exelberg	OE1AOA	\N	\N	\N	\N	\N	inactive	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	49	WIEN EXELBERG	dumb2	OE3
2203	repeater_voice	438.8375	431.2375	12.5	V	OE8XKK	46.608914	14.14479	0101000020110F0000E92BF7D1BE0638414B59AEB8B16C5641	JN76BO	https://www.peakbagger.com/peak.aspx?pid=47628	848.6	934	\N	KLagenfurt	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	185	PYRAMIDENKOGEL	dumb2	OE8
2121	repeater_voice	438.65	431.05	12.5	V	OE5XLL	48.38515	14.25445	0101000020110F0000FAE8931D6E363841F51A11BC888A5741	JN78DJ	https://hamnetdb.net/?m=site&q=oe5xll&as=-All-	926.8	926	\N	Linz	Lichtenberg	OE5RNL	\N	\N	\N	\N	\N	inactive	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trial	2021-10-16 14:40:51.350258+02	103	LINZ LICHTENBERG	dumb2	OE5
2241	packet_radio	438.475	430.875	12.5	V	OE5XBL	\N	\N	\N	JN68PC	\N	\N	\N	\N	\N	St. Johann am Walde	OE5HPM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	St. Johann am Walde	\N	\N
2018	repeater_voice	51.95	51.35	12.5	V	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Notrufrelais	2021-10-16 14:40:51.350258+02	1	MOBILES NOTFUNKRELAIS OE	dumb2	\N
2052	repeater_voice	51.89	51.29	12.5	V	OE2XZR	47.805128	13.112955	0101000020110F0000066C30790F4636411387E905202C5741	JN67NT	https://www.peakbagger.com/peak.aspx?pid=96034	1281	1288	\N	Salzburg	Gaisberg	OE2AIP	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed	2021-10-16 14:40:51.350258+02	34	SALZBURG GAISBERG	dumb2	OE2
2056	repeater_voice	1298.2	1270200	12.5	V	OE3X..	48.43338	15.471389	0101000020110F0000A84E35259B473A41640105C46E925741	JN78RL	https://hamnetdb.net/?q=oe3xsa	696.8	710	\N	Krems	Sandl	OE3WLS	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	38	KREMS SANDL	dumb2	OE3
2125	repeater_voice	145.775	145.175	12.5	V	OE5XUL	48.20026	13.58142	0101000020110F0000E5DB36C2C4113741232B37F7526C5741	JN68SE	https://hamnetdb.net/?m=site&q=oe5xul&as=-All-&tab=	565	555	\N	Ried	Geiersberg	OE5MLL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	107	RIED GEIERSBERG	dumb2	OE5
2082	repeater_voice	1298.5	1270500	12.5	V	OE3XPC	47.97206	15.61039	0101000020110F0000946677AA0C843A41C1E9D6F72F475741	JN77TX	Google Maps Traisnerhütte	1314.2	1313	\N	Lilienfeld	Hinteralm Traisnerhütte	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	\N	\N	\N	inactive	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	64	LILIENFELD HINTERALM	dumb2	OE3
2194	repeater_voice	1298.2	1270.2	12.5	V	OE8X..	46.728051	14.429426	0101000020110F00001A80D15A84823841A1B69F5F917F5641	JN76FR	https://www.peakbagger.com/peak.aspx?pid=-60071	1059	1066	\N	Klagenfurt	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	176	MAGDALENSBERG	dumb2	OE8
2226	repeater_voice	438.55	430.95	12.5	V	OE9XMV	\N	\N	\N	JN47TF	nicht in RufzL	\N	530	\N	Feldkirch	Frastanz	OE9VVV	\N	\N	\N	\N	\N	historic	t	\N	\N	123	\N	\N	\N	\N	t	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	208	FELDKIRCH FRASTANZ	dumb2	\N
2103	repeater_voice	51.81	51.21	12.5	V	OE5SIX	\N	\N	\N	JN68PC	* in RufzL	\N	623	\N	\N	\N	OE5DXL	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	85	ST. JOHANN IM WALDE	dumb2	\N
2219	repeater_voice	1298.575	1270575	12.5	V	OE9X..	47.50601	9.7792	0101000020110F000040437A90679C3041B4D1D19DD9FB5641	JN47VM	https://hamnetdb.net/?q=oe9xpr	1023.5	1020	\N	Bregenz	Pfänder	OE9HLH	\N	\N	\N	\N	\N	planned	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	201	BREGENZ PFÄNDER	dumb2	OE9
2233	repeater_voice	439.05	431.45	12.5	V	OE9XXI	47.39798	9.72684	0101000020110F0000943D36E0A2853041EF35738D7BEA5641	JN47UJ	Google Maps Niederbahn 1 Top 22	429	429	\N	Dornbirn	Stadt	OE9VVV	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	215	DORNBIRN	dumb2	OE9
2214	repeater_voice	438.7	431.1	12.5	V	OE8XPK	46.518507	14.772985	0101000020110F00003B2BEE2AE9173941AFBB9250665E5641	JN76IM	https://hamnetdb.net/?m=site&q=oe8xpk&as=-All-	1677.9	1700	\N	Bleiburg/Pliberk	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	196	PETZEN	dumb2	OE8
2216	repeater_voice	438.55	430.95	12.5	V	OE8XVK	46.61612	13.85777	0101000020110F000013D561E6EF893741B7C559A9D56D5641	JN66WO	Google Maps	494.1	496	\N	Villach	Stadt/LKH	OE8WUR	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	198	VILLACH LKH	dumb2	OE8
2215	repeater_voice	439.0875	431.4875	12.5	V	OE8XPK	46.518507	14.772985	0101000020110F00003B2BEE2AE9173941AFBB9250665E5641	JN76IM	https://hamnetdb.net/?m=site&q=oe8xpk&as=-All-	1677.9	1700	\N	Bleiburg/Pliberk	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	197	PETZEN	dumb2	OE8
2160	repeater_voice	438.4	430.8	12.5	V	OE7XCJ	47.264819	11.39865	0101000020110F00001F42EAE99B5C334191C2F1B91FD55641	JN57QG	https://hamnetdb.net/?m=site&q=oe7xcj&as=-All-&tab=	579.6	582	\N	Innsbruck	Stadt/Brixner Straße	OE7AAI	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	142	INNSBRUCK KLUBSTATION	dumb2	OE7
2157	repeater_voice	439.05	431.45	12.5	V	OE7XBI	47.242985	11.181174	0101000020110F0000ED599D980AFE32413142477FA0D15641	JN57OF	https://hamnetdb.net/?m=site&q=oe7xbi&as=-All-	1938	1939	\N	Oberpferfuss	Rangger Köpl	OE7WSH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02	139	OBERPFERFUSS RANGGER KÖPFL	dumb2	OE7
2255	packet_radio	\N	\N	12.5	V	OE1XIK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Winlink	\N	2021-10-21 12:45:40.647422+02	\N	\N	\N	\N
2222	repeater_voice	145.575	144.975	12.5	V	OE9XDV	\N	\N	\N	JN47TE	nicht in RufzL	\N	1010	\N	Feldkirch	Bazora	OE9VVV	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	204	FELDKIRCH BAZORA	dumb2	\N
2220	repeater_voice	438.25	430.65	12.5	V	OE9XDV	\N	\N	\N	JN47TE	nicht in RufzL	\N	1010	\N	Feldkirch	Bazora	OE9VVV	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	202	FRASTANZ BAZORA	dumb2	\N
2227	repeater_voice	145.65	145.05	12.5	V	OE9XVI	47.20918	9.591069	0101000020110F00007A72D0EA984A3041DD5A502A37CC5641	JN47TF	https://hamnetdb.net/?m=site&q=oe9xvi&as=-All-&tab=	1314.7	1320	\N	Feldkirch	Vorderälpele	OE9HMV	\N	\N	\N	\N	\N	historic	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	ATV info 18h30/19h	2021-10-16 14:40:51.350258+02	209	FELDKIRCH VORDERÄLPELE	dumb2	OE9
2019	repeater_voice	51.97	51.37	12.5	V	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	unspecified digital	\N	Digitales Voice Relais OE	2021-10-16 14:40:51.350258+02	2	DIGITAL VOICE RELAIS OE	dumb2	\N
2027	repeater_voice	145.575	144.975	12.5	V	OE1XDS	48.22075	16.34684	0101000020110F00006228A6E749C43B417C1A1FAAAA6F5741	JN88EF	Google Maps	197.6	306	\N	Wien	Stadt/AKH	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	10	WIEN AKH	dumb2	OE1
2140	repeater_voice	145.6375	145.0375	12.5	V	OE6XDF	46.94991	15.37989	0101000020110F00005624F485D11F3A4175C6117CD3A25641	JN76QW	https://hamnetdb.net/?q=oe6xpd	348.5	350	\N	Graz	Dobl	OE6THH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	122	GRAZ-DOBL	dumb2	OE6
2026	repeater_voice	438.525	430.925	12.5	V	OE1XDS	48.22075	16.34684	0101000020110F00006228A6E749C43B417C1A1FAAAA6F5741	JN88EF	Google Maps	197.6	306	\N	Wien	Stadt/AKH	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	9	WIEN AKH	dumb2	OE1
2074	repeater_voice	438.3	430.7	12.5	V	OE3XNK	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AU	Google Maps	917.8	841	\N	Wr. Neustadt	Hohe Wand	OE3GBB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	56	WIENER NEUSTADT HOHE WAND	dumb2	OE3
2062	repeater_voice	439.025	431.425	12.5	V	OE3XEU	48.7931928	15.3499052	0101000020110F00003C486EA1C7123A41BEB756C798CD5741	JN78QT	OSM; https://hamnetdb.net/?q=oe3xer	679.5	695	\N	Waidhofen an der Thaya	Frauenstaffel	OE3KMA	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	44	WAIDH./THAYA FRAUENSTAFFEL	dumb2	OE3
2061	repeater_voice	145.7875	145.1875	12.5	V	OE3XES	48.7931928	15.3499052	0101000020110F00003C486EA1C7123A41BEB756C798CD5741	JN78QT	OSM, https://hamnetdb.net/?q=oe3xer	679.5	695	\N	Waidhofen an der Thaya	Frauenstaffel	OE3KMA	\N	\N	\N	t	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	43	WAIDH./THAYA FRAUENSTAFFEL	dumb2	OE3
2063	repeater_voice	1298.225	1270225	12.5	V	OE3XFC	47.530448	15.9145156	0101000020110F0000D61CD7C54B083B4169FBABA6C8FF5641	JN77XM	https://www.peakbagger.com/peak.aspx?pid=10151	1739.6	1743	\N	Mürzzuschlag	Hochwechsel	OE4KMU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	45	HOCHWECHSEL	dumb2	OE3
2081	repeater_voice	438.7	431.1	12.5	V	OE3XPC	47.97206	15.61039	0101000020110F0000946677AA0C843A41C1E9D6F72F475741	JN77TX	Google Maps Traisnerhütte	1314.2	1314	\N	Lilienfeld	Hinteralm Traisnerhütte	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	\N	\N	\N	active	t	\N	\N	162.2	t	\N	\N	t	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	cjb confirmed	2021-10-16 14:40:51.350258+02	63	LILIENFELD HINTERALM	dumb2	OE3
2021	repeater_voice	438.5	430.9	12.5	V	OE1XAR	48.3106475	16.3827774	0101000020110F0000A5541D70EAD33B41F64872FF587E5741	JN88EH	OSM	305.7	304	\N	Wien	Bisamberg	OE3NSC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	4	WIEN BISAMBERG	dumb2	OE1
2020	repeater_voice	430.4125	430.4125	12.5	V	OE1XAR	48.3106475	16.3827774	0101000020110F0000A5541D70EAD33B41F64872FF587E5741	JN88EH	OSM	305.7	304	\N	Wien	Bisamberg	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	3	WIEN BISAMBERG	dumb2	OE1
2057	repeater_voice	438.725	431.125	12.5	V	OE3XAV	48.66351	16.59337	0101000020110F0000ABD1BA7F7D2F3C4169E2837039B85741	\N	Google Maps/Kleinhadersdf Untere Ortsstra�e 24	213.5	204	\N	Kleinhadersdorf	Ort	OE3PKB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	39	KLEINHADERSDORF	dumb2	OE3
2051	repeater_voice	438.975	431.375	12.5	V	OE2XWR	47.188104	12.687513	0101000020110F0000845C917C0F8D35416D446EEAD7C85641	JN67IE	https://www.peakbagger.com/peak.aspx?pid=10110	3196.8	3035	\N	Zell am See	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	33	KITZSTEINHORN	dumb2	OE2
2024	repeater_voice	1298.65	1270650	12.5	V	OE1XDS	48.22075	16.34684	0101000020110F00006228A6E749C43B417C1A1FAAAA6F5741	JN88EF	Google Maps	197.6	306	\N	Wien	Stadt/AKH	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	A	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	7	WIEN AKH	dumb2	OE1
2127	repeater_voice	145.6	145	12.5	V	OE6XAG	47.198505	15.465789	0101000020110F00002D1396C12B453A415F2BE4E281CA5641	JN77RE	https://www.peakbagger.com/peak.aspx?pid=89381	1444.3	144.5	\N	Graz	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	t	\N	\N	103.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	109	GRAZ SCHÖCKL	dumb2	OE6
2050	repeater_voice	439.0875	431.4875	12.5	V	OE2XSV	47.05397	12.957194	0101000020110F00005DFFF93C54023641C37B6EF369B35641	JN67LA	https://www.peakbagger.com/peak.aspx?pid=88145	3099.6	3115	\N	Heiligenblut	Hoher Sonnblick	OE7JTK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	32	SONNBLICK	dumb2	OE2
2093	repeater_voice	438.6	431	12.5	V	OE3XWJ	48.33373	15.3332	0101000020110F000014BE2704840B3A41D4D8A7121F825741	JN78QI	Google Maps	942.5	960	\N	Spitz an der Donau	Jauerling	OE1KBC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	75	JAUERLING	dumb2	OE3
2096	repeater_voice	438.575	430.975	12.5	V	OE3XWW	47.510703	16.037665	0101000020110F0000764189B3D83D3B41843CCEF79AFC5641	JN87AM	https://hamnetdb.net/?m=site&q=oe3xww&as=-All-	947.6	1002	\N	Mönichkirchen	Ort	OE3RPU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	t	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	78	MÖNICHKIRCHEN	dumb2	OE3
2100	repeater_voice	438.725	431.125	12.5	V	OE4XSB	47.875253	16.470265	0101000020110F0000C1F35583F5F93B415C057F9A7B375741	JN87FV	https://www.bergfex.at/sommer/burgenland/touren/wanderung/29623,hornstein-rundwanderung-zum-sonnenberg/	438.7	471	\N	Eisenstadt	Hornstein/Sonnenberg	OE4JHW	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	82	HORNSTEIN SONNENBERG	dumb2	OE4
2066	repeater_voice	438.75	431.15	12.5	V	OE3XHW	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	Google Maps	917.8	1065	\N	Wr. Neustadt	Hohe Wand	OE3GWC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	48	WR.NEUSTADT HOHE WAND	dumb2	OE3
2085	repeater_voice	438.9	431.3	12.5	V	OE3XRB	47.996538	14.764472	0101000020110F0000F8423F81351439412323A6B9294B5741	JN77JX	https://hamnetdb.net/?m=site&q=oe3xrb&as=-All-	713.2	712	\N	Amstetten	Sonnenberg	OE3JWB	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	67	AMSTETTEN SONNTAGBERG	dumb2	OE3
2089	repeater_voice	438.925	431.325	12.5	V	OE3XSU	48.1746467	14.5319725	0101000020110F0000346C67C71BAF3841BCBA36CA25685741	JN78GE	Guess, St. Valentin	267.5	317	\N	St. Valentin	Rittmannsberg 	OE5FXN	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	71	ST. VALENTIN	dumb2	OE3
2119	repeater_voice	145.6	145	12.5	V	OE5XLL	48.38515	14.25445	0101000020110F0000FAE8931D6E363841F51A11BC888A5741	JN78DJ	https://hamnetdb.net/?m=site&q=oe5xll&as=-All-	926.8	926	\N	Linz	Lichtenberg	OE5RNL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	planed/trail	2021-10-16 14:40:51.350258+02	101	LINZ LICHTENBERG	dumb2	OE5
2084	repeater_voice	438.55	430.95	12.5	V	OE3XRB	47.996538	14.764472	0101000020110F0000F8423F81351439412323A6B9294B5741	JN77JX	https://hamnetdb.net/?m=site&q=oe3xrb&as=-All-	713.2	712	\N	Amstetten	Sonnenberg	OE3NRS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	66	AMSTETTEN SONNTAGBERG	dumb2	OE3
2256	packet_radio	\N	\N	12.5	V	OE1XLR	48.1899867	16.3404457	0101000020110F0000C8943B1882C13B4110352F10A66A5741	\N	OSM	182.3	\N	\N	Wien	Eisvogelgasse	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N		\N	2021-10-21 12:45:40.647422+02	\N	Eisvogelgasse	\N	OE1
2240	packet_radio	438.125	430.525	12.5	V	OE2XZR	47.805128	13.112955	0101000020110F0000066C30790F4636411387E905202C5741	JN67NT	\N	1281	\N	\N	Salzburg	Gaisberg	OE2WAO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox,Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Gaisberg	\N	OE2
2090	repeater_voice	438.4	430.8	12.5	V	OE3XTR	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	Google Maps	917.8	920	\N	Wr. Neustadt	Hohe Wand	OE3KLU	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	72	WIENER NEUSTADT HOHE WAND	dumb2	OE3
2108	repeater_voice	438.95	431.35	12.5	V	OE5XDO	48.502872	13.825623	0101000020110F0000A241F04FF57B3741CB313794D39D5741	JN68VM	https://hamnetdb.net/?m=site&q=oe5xdo&as=-All-	812.8	833	\N	Pfarrkirchen im Mühlkreis	Ort	OE5MKP	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	90	PFARRKIRCHEN i.M.	dumb2	OE5
2117	repeater_voice	145.7125	145.1125	12.5	V	OE5XKL	47.524287	13.69208	0101000020110F000004BF9D5FE3413741C7D0DAB9CAFE5641	JN67UM	https://www.peakbagger.com/peak.aspx?pid=61502	2106	2100	\N	Obertraun	Krippenstein	OE5VFM	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	99	OBERTRAUN KRIPPENSTEIN	dumb2	OE5
2110	repeater_voice	145.75	145.15	12.5	V	OE5XGL	47.8981318	13.8219805	0101000020110F0000B85EBDD45F7A3741BA690513313B5741	JN67VV	https://www.peakbagger.com/peak.aspx?pid=-76602	976.6	965	\N	Gmunden	Grünberg	OE5RDL	\N	\N	\N	\N	\N	active	t	\N	123	123	t	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	92	GMUNDEN GRÜNBERG	dumb2	OE5
2111	repeater_voice	438.8	431.2	12.5	V	OE5XGL	47.8981318	13.8219805	0101000020110F0000B85EBDD45F7A3741BA690513313B5741	JN67VV	https://www.peakbagger.com/peak.aspx?pid=-76602	976.6	965	\N	Gmunden	Grünberg	OE5EUL	\N	\N	\N	\N	\N	active	t	\N	123	123	\N	\N	\N	t	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	93	GMUNDEN GRÜNBERG	dumb2	OE5
2122	repeater_voice	438.2875	430.6875	12.5	V	OE5XOL	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ	https://hamnetdb.net/?m=site&q=oe5xol&as=-All-&tab=	955.3	955	\N	Linz	Breitenstein	OE5PON	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	32,95	\N	\N	\N	\N	\N	\N	\N	conf	2021-10-16 14:40:51.350258+02	104	LINZ BREITENSTEIN	dumb2	OE5
2094	repeater_voice	439.075	431.475	12.5	V	OE3XWU	47.530448	15.9145156	0101000020110F0000D61CD7C54B083B4169FBABA6C8FF5641	JN77XM	https://www.peakbagger.com/peak.aspx?pid=10151	1739.6	1743	\N	Mürzzuschlag	Hochwechsel	OE4RLC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	? /4KMU	2021-10-16 14:40:51.350258+02	76	HOCHWECHSEL	dumb2	OE3
2126	repeater_voice	51.85	51.25	12.5	V	OE5XYP	48.05321	14.41718	0101000020110F000092EAE222317D384165DCC2E95F545741	JN78FB	https://hamnetdb.net/?m=site&q=oe5xyp&as=-All-&tab=	336.8	330	\N	Steyr	Stadt	OE5VLLF	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	inactive	2021-10-16 14:40:51.350258+02	108	STEYR	dumb2	OE5
2102	repeater_voice	438.55	430.95	12.5	V	OE4XUB	47.659535	16.390592	0101000020110F00004E07F15A50D73B41C71D01D697145741	JN87EP	https://www.bergfex.at/sommer/sieggraben/highlights/8792-naturwanderwege-in-sieggraben/?mapstate=47.659535,16.390592,20,o,385,47.649905,16.380083	605.5	605	\N	Mattersburg	Brentenriegel	OE4KZU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	84	BRENTENRIEGEL	dumb2	OE4
2224	repeater_voice	438.525	430.925	12.5	V	OE9XFV	47.49003	9.74761	0101000020110F0000EF814DFBAA8E3041CD4FD35E47F95641	JN47VL	Google Maps Gebhardsberg	595.9	550	\N	Bregenz	Gebhartsberg	OE9AFV	\N	\N	\N	\N	\N	active	t	\N	\N	67	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	APCO P25	\N	\N	2021-10-16 14:40:51.350258+02	206	BREGENZ GEBHARDSBERG	dumb2	OE9
2120	repeater_voice	438.475	430.875	12.5	V	OE5XLL	48.38515	14.25445	0101000020110F0000FAE8931D6E363841F51A11BC888A5741	JN78DJ	https://hamnetdb.net/?m=site&q=oe5xll&as=-All-	926.8	926	\N	Linz	Lichtenberg	OE5RNL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02	102	LINZ LICHTENBERG	dumb2	OE5
2087	repeater_voice	438.35	430.75	12.5	V	OE3XSA	48.43338	15.471389	0101000020110F0000A84E35259B473A41640105C46E925741	JN78RL	https://hamnetdb.net/?q=oe3xsa	696.8	710	\N	Krems	Sandl	OE3WLS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	69	KREMS SANDL	dumb2	OE3
2109	repeater_voice	432.9	145.225	12.5	V	OE5XFN	47.99241	13.4224	0101000020110F00004E8BB4BB9ECC3641268E380E7E4A5741	JN67RX	Rougth estimate, Google Maps Pointen	566.6	571	\N	Frankenmark	Pointen/Wasserbehälter	OE5DZL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	91	FRANKENMARKT (Kopplung mit OE5XFM)	dumb2	OE5
2113	repeater_voice	438.75	431.15	12.5	V	OE5XHO	48.0072	14.45225	0101000020110F000038825E1C718C38412AE07B2FE54C5741	JN78FA	https://hamnetdb.net/?m=site&q=oe5xHO&as=-All-	657.7	51	\N	Steyr	Damberg	OE5VLL	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	95	STEYR DAMBERG	dumb2	OE5
2029	repeater_voice	439	431.4	12.5	V	OE1XFU	48.215096	16.261484	0101000020110F0000ACF7501E2C9F3B41340B5D82BE6E5741	JN88DF	https://www.peakbagger.com/peak.aspx?pid=-80350	432.2	380	\N	Wien	Satzberg	OE1FFS	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	12	WIEN SATZBERG	dumb2	OE1
2032	repeater_voice	438.2125	430.6125	12.5	V	OE1XFV	48.21328	16.32542	0101000020110F0000B5B1FE70F9BA3B41C55515AA726E5741	\N	\N	207.1	205	\N	Wien	Ottakring	\N	http://oe1xfv.ddns.net:8080/	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	\N	dstar.at-Liste	dumb2	OE1
2023	repeater_voice	1298.25	1270250	12.5	V	OE1XCA	48.16803	16.3454	0101000020110F0000D7FBD49AA9C33B418BE004AD11675741	JN88EE	https://hamnetdb.net/?m=as&q=oe1xca&tab=	222.5	240	\N	Wien	Wienerberg	OE1MCU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	6	WIEN WIENERBERG	dumb2	OE1
2083	repeater_voice	438.675	431.075	12.5	V	OE3XQA	48.24876033	16.2440474	0101000020110F000039E4C11597973B41C415E6FA3C745741	JN88CF	OSM	514.8	577	\N	Wien	Exelberg	OE1BAD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	65	WIEN EXELBERG	dumb2	OE3
2022	repeater_voice	438.475	430.875	12.5	V	OE1XAT	48.270327	16.29324	0101000020110F000093CA1F2EFBAC3B41ABBF9781C2775741	JN88DG	https://www.peakbagger.com/peak.aspx?pid=10142	541.2	559	\N	Wien	Hermannskogel	OE1KBC	\N	\N	\N	\N	t	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	5	WIEN HERMANNSKOGEL	dumb2	OE1
2058	repeater_voice	438.85	431.25	12.5	V	OE3XCR	47.463146	16.22183	0101000020110F0000DE3CF7DAED8D3B41AD2B816BF4F45641	JN87CL	https://www.peakbagger.com/peak.aspx?pid=76556	894.8	850	\N	Schäffern	Hutwisch	OE4KZU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02	40	HUTWISCH	dumb2	OE3
2059	repeater_voice	438.85	431.25	12.5	V	OE3XDA	48.034278	14.951167	0101000020110F0000C4A3154C64653941282B94D74B515741	JN78LA	https://hamnetdb.net/?m=site&q=oe3xda&as=-All-	711.6	711	\N	Randegg	Hochkogelberg	OE3JWC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	41	RANDEGG HOCHKOGELBERG	dumb2	OE3
2049	repeater_voice	438.9	431.3	12.5	V	OE2XPR	47.914961	12.996526	0101000020110F00006EEE09A86E1336415D1220C1EB3D5741	JN67MW	https://www.peakbagger.com/peak.aspx?pid=88319	831.7	725	\N	Salzburg	Haunsberg	OE2WAO	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	31	HAUNSBERG	dumb2	OE2
2075	repeater_voice	145.6375	145.0375	12.5	V	OE3XNR	48.672816	14.77828	0101000020110F000062FCB99A361A394181287D97C1B95741	JN78JQ	GPS, Sysop	1005.4	1017	\N	Weitra	Nebelstein	OE3IGW	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	57	NEBELSTEIN	dumb2	OE3
2262	packet_radio	438	438	12.5	V	OE9XRK	\N	\N	\N	JN47TG	\N	\N	\N	\N	\N	Feldkirch	\N	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Feldkirch	\N	\N
2076	repeater_voice	438.875	431.275	12.5	V	OE3XNR	48.672816	14.77828	0101000020110F000062FCB99A361A394181287D97C1B95741	JN78JQ	GPS, Sysop	1005.4	1017	\N	Weitra	Nebelstein	OE3IGW	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	58	NEBELSTEIN	dumb2	OE3
2171	repeater_voice	145.7	145.1	12.5	V	OE7XLI	46.82166	12.70025	0101000020110F0000CB1CEA5C9992354104CCDB376D8E5641	JN66IT	Approx Gmaps	2018.9	2023	\N	Lienz	Hochstein	OE7JTK	\N	\N	\N	t	\N	active	t	Tone 1750	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	153	LIENZ HOCHSTEIN	dumb2	OE7
2115	repeater_voice	438.975	431.375	12.5	V	OE5XIM	48.5599155	14.2690062	0101000020110F0000DD761A81C23C3841901775E030A75741	JN78DN	OSM	1105.1	1100	\N	Bad Leonfelden	Sternstein	OE5KPN	\N	\N	\N	\N	\N	active	t	\N	123	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	97	BAD LEONFELDEN STERNSTEIN	dumb2	OE5
2116	repeater_voice	439.0625	431.4625	12.5	V	OE5XIM	48.5599155	14.2690062	0101000020110F0000DD761A81C23C3841901775E030A75741	JN78DN	OSM	1105.1	1100	\N	Bad Leonfelden	Sternstein	OE5KPN	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	98	BAD LEONFELDEN STERNSTEIN	dumb2	OE5
2079	repeater_voice	145.65	145.05	12.5	V	OE3XPA	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	726	\N	St. Pölten	Kaiserkogel	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	cjb confirmed	2021-10-16 14:40:51.350258+02	61	ST. PÖLTEN-KAISERKOGEL	dumb2	OE3
2123	repeater_voice	438.575	430.975	12.5	V	OE5XOL	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ	https://hamnetdb.net/?m=site&q=oe5xol&as=-All-&tab=	955.3	955	\N	Linz	Breitenstein	OE5PON	\N	\N	\N	\N	\N	active	t	\N	123	123	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	conf	2021-10-16 14:40:51.350258+02	105	LINZ BREITENSTEIN	dumb2	OE5
2106	repeater_voice	438.725	431.125	12.5	V	OE5XDM	47.467376	13.627424	0101000020110F0000B56E87E6C5253741D4C58C8DA2F55641	JN67TL	https://www.peakbagger.com/peak.aspx?pid=-23371	2589.9	2713	\N	Dachstein	Hunerkogel	OE5MLL	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	88	DACHSTEIN HUNERKOGEL	dumb2	OE5
2101	repeater_voice	145.775	145.175	12.5	V	OE4XUB	47.659535	16.390592	0101000020110F00004E07F15A50D73B41C71D01D697145741	JN87EP	https://www.bergfex.at/sommer/sieggraben/highlights/8792-naturwanderwege-in-sieggraben/?mapstate=47.659535,16.390592,20,o,385,47.649905,16.380083	605.5	605	\N	Mattersburg	Brentenriegel	OE4KZU	\N	\N	\N	\N	t	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling OE3XCR-OE4XUB	2021-10-16 14:40:51.350258+02	83	BRENTENRIEGEL	dumb2	OE4
2186	repeater_voice	145.6625	145.0625	12.5	V	OE7XWH	47.28231	10.91478	0101000020110F0000FDC270C0338A324159D1E426EDD75641	JN57LG	Google Maps	1491.2	1497	\N	Silz	Grünberg	OE7MST	\N	\N	\N	t	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	168	SILZ -GRÜNBERG	dumb2	OE7
2188	repeater_voice	438.6	431	12.5	V	OE7XWT	47.57772	12.20958	0101000020110F0000B967783A3CBD34417675A3F465075741	JN67CN	https://hamnetdb.net/?m=site&q=oe7xwt&as=-All-	1269.2	1272	\N	Kufstein	Weinbergerhaus	OE7MPI	\N	\N	\N	\N	\N	active	t	\N	\N	77	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	170	KUFSTEIN WEINBERGERHAUS	dumb2	OE7
2190	repeater_voice	145.675	145.075	12.5	V	OE7XZH	47.381759	11.874329	0101000020110F0000BCA4FE41742B34413AF762C0E0E75641	JN57WJ	https://hamnetdb.net/?m=site&q=oe7xzh&as=-All-&tab=	1049.7	1046	\N	Bruuck am Ziller	Brückerberg	OE7FMI	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	172	BRUCK AM ZILLER -BRUCKERBERG	dumb2	OE7
2192	repeater_voice	145.575	432.575	12.5	V	OE7XZR	47.4211969	10.9843067	0101000020110F0000DE2EB66D6FA8324123B50E4B36EE5641	JN57LK	https://hamnetdb.net/?m=site&q=oe7xzr&as=-All-&tab=	2935.7	2980	\N	Ehrwald	Zugspitze Ö	OE7DA	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	174	EHRWALD ZUGSPITZE	dumb2	OE7
2195	repeater_voice	438.65	431.05	12.5	V	OE8XCK	46.61189	14.29801	0101000020110F00009F6C4B315F493841A749E9482A6D5641	JN76EO	Google Maps, Roesegger Str 20	440.7	440	\N	Klagenfurt	Rossegger Str/LWZ	OE8RGQ	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	177	KLAGENFURT LANDESWARNZENTRALE	dumb2	OE8
2197	repeater_voice	438.9	431.3	12.5	V	OE8XFK	46.603397	13.670989	0101000020110F0000101EBC88B73837412A541C3CD26B5641	JN66UO	https://www.peakbagger.com/peak.aspx?pid=10133	2159	2116	\N	Villach	Dobratsch	OE8URQ	\N	\N	\N	t	t	active	t	\N	\N	88.5	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	179	VILLACH DOBRATSCH	dumb2	OE8
2204	repeater_voice	438.3	430.7	12.5	V	OE8XKP	46.93639	14.67506	0101000020110F00001C2AE13454ED384108F3655EACA05641	\N	Approx Gmaps	1626	1818	\N	Wolfsberg	Klippitztörl	OE1BAD	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	186	KLIPPITZTÖRL	dumb2	OE8
2206	repeater_voice	145.625	145.025	12.5	V	OE8XMK	46.728051	14.429426	0101000020110F00001A80D15A84823841A1B69F5F917F5641	JN76FR	https://www.peakbagger.com/peak.aspx?pid=-60071	1059	1036	\N	Klagenfurt	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	188	KLAGENFURT-MAGDALENSBERG	dumb2	OE8
2242	packet_radio	144.925	144.925	12.5	V	OE7XHR	\N	\N	\N	JN57PE	\N	\N	\N	\N	\N	Axams / Hoadl	OE7MBT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Axams / Hoadl	\N	\N
2105	repeater_voice	438.775	431.175	12.5	V	OE5XBR	48.28849	14.27855	0101000020110F000059E44EEAE840384145D8450CBA7A5741	JN78DH	Rufzl Hugo Wolf Str 32, Google Maps	326.9	320	\N	Linz	Stadt/Froschberg	OE5AJP	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	87	LINZ FROSCHBERG	dumb2	OE5
2114	repeater_voice	438.25	430.65	12.5	V	OE5XIM	48.5599155	14.2690062	0101000020110F0000DD761A81C23C3841901775E030A75741	JN78DN	OSM	1105.1	1100	\N	Bad Leonfelden	Sternstein	OE5KPN	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	t	t	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	96	BAD LEONFELDEN STERNSTEIN	dumb2	OE5
2187	repeater_voice	438.5	430.9	12.5	V	OE7XWJ	47.15829	11.84865	0101000020110F0000102441AF49203441AA54455A13C45641	\N	Google Maps, Stillupklam 802	644	640	\N	Mayhofen	Stilluppklamm	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	169	ZILLERTAL MAYRHOFEN KLUBSTATION	dumb2	OE7
2191	repeater_voice	438.45	430.85	12.5	V	OE7XZH	47.381759	11.874329	0101000020110F0000BCA4FE41742B34413AF762C0E0E75641	JN57WJ	https://hamnetdb.net/?m=site&q=oe7xzh&as=-All-&tab=	1049.7	1043	\N	Zillertal	Bruckerberg	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	173	ZILLERTAL BRUCKERBERG	dumb2	OE7
2199	repeater_voice	438.45	430.85	12.5	V	OE8XGK	46.56579	13.83948	0101000020110F00000041CFDDFB813741522AEA6DDF655641	JN66WN	Google Maps, Neumühlern 48	507.5	567	\N	Villach	Finkenstein/Neumüllern	OE8VIK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	181	FINKENSTEIN	dumb2	OE8
2205	repeater_voice	439.05	431.45	12.5	V	OE8XKQ	46.695	13.914167	0101000020110F0000338339FC75A2374154537DE8537A5641	JN66WQ	https://www.peakbagger.com/peak.aspx?pid=13706	1908.7	1897	\N	Villach	Gerlitzen	OE8PKR	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	187	GERLITZE	dumb2	OE8
2135	repeater_voice	438.625	431.025	12.5	V	OE6XCD	47.574167	15.79	0101000020110F0000F4D576C226D23A414D621C62D3065741	JN77VN	https://www.peakbagger.com/peak.aspx?pid=13769	1781.2	1782	\N	Mürzzuschlag	Stuhleck	OE3KLU	\N	\N	\N	\N	t	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	117	STUHLECK	dumb2	OE6
2129	repeater_voice	438.875	431.275	12.5	V	OE6XAG	47.198505	15.465789	0101000020110F00002D1396C12B453A415F2BE4E281CA5641	JN77RE	https://www.peakbagger.com/peak.aspx?pid=89381	1444.3	144.5	\N	Graz	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	111	GRAZ SCHÖCKL	dumb2	OE6
2137	repeater_voice	1298.2	1270200	12.5	V	OE6XDD	47.198505	15.465789	0101000020110F00002D1396C12B453A415F2BE4E281CA5641	JN77RE	https://www.peakbagger.com/peak.aspx?pid=89381	1444.3	144.5	\N	Graz	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	119	GRAZ SCHÖCKL	dumb2	OE6
2270	packet_radio	433.625	433.625	12.5	V	OE1XDU	\N	\N	\N	\N	vermutlich Gußhausstraße	\N	\N	\N	Wien	Wieden/Gußhausstraße	OE1RSA	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-23 18:38:59.606853+02	\N	\N	\N	\N
2269	packet_radio	144.8	144.8	12.5	V	OE1XDU	\N	\N	\N	\N	vermutlich Gußhausstraße	\N	\N	\N	Wien	Wieden/Gußhausstraße	OE1RSA	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	APRS	\N	2021-10-23 18:38:59.606853+02	\N	\N	\N	\N
2132	repeater_voice	438.975	431.375	12.5	V	OE6XBF	46.845678	15.931635	0101000020110F0000077AE67EBD0F3B41B07B95443E925641	JN76XU	https://www.peakbagger.com/peak.aspx?pid=95413	607.9	609	\N	Bad Gleichenberg	Stradner Kogel	OE6TYG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	114	STRADNER KOGEL	dumb2	OE6
2133	repeater_voice	145.65	145.05	12.5	V	OE6XBG	47.40554	15.35936	0101000020110F000013125522E4163A41E620C564B2EB5641	JN77QJ	https://hamnetdb.net/?m=site&q=oe6xbg&as=-All-&tab=	1618	1630	\N	Bruck an der Mur	Rennfeld	OE6MKD	\N	\N	\N	\N	\N	active	t	\N	\N	103.5	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	115	BRUCK A D.MUR RENNFELD	dumb2	OE6
2158	repeater_voice	439.075	431.475	12.5	V	OE7XBI	47.242985	11.181174	0101000020110F0000ED599D980AFE32413142477FA0D15641	JN57OF	https://hamnetdb.net/?m=site&q=oe7xbi&as=-All-	1938	1939	\N	Oberpferfuss	Rangger Köpl	OE7WSH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	140	OBERPFERFUSS RANGGER KÖPFL	dumb2	OE7
2202	repeater_voice	439.075	431.475	12.5	V	OE8XKK	46.608914	14.14479	0101000020110F0000E92BF7D1BE0638414B59AEB8B16C5641	JN76BO	https://www.peakbagger.com/peak.aspx?pid=47628	848.6	934	\N	KLagenfurt	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	184	PYRAMIDENKOGEL	dumb2	OE8
2200	repeater_voice	145.5875	144.9875	12.5	V	OE8XKK	46.608914	14.14479	0101000020110F0000E92BF7D1BE0638414B59AEB8B16C5641	JN76BO	https://www.peakbagger.com/peak.aspx?pid=47628	848.6	934	\N	KLagenfurt	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	182	PYRAMIDENKOGEL	dumb2	OE8
2207	repeater_voice	438.225	430.625	12.5	V	OE8XMK	46.728051	14.429426	0101000020110F00001A80D15A84823841A1B69F5F917F5641	JN76FR	https://www.peakbagger.com/peak.aspx?pid=-60071	1059	1036	\N	Klagenfurt	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	\N	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	189	KLAGENFURT MAGDALENSBERG	dumb2	OE8
2198	repeater_voice	1298.1	1270.1	12.5	V	OE8XFK	46.603397	13.670989	0101000020110F0000101EBC88B73837412A541C3CD26B5641	JN66UO	https://www.peakbagger.com/peak.aspx?pid=10133	2159	2166	\N	Villach	Dobratsch	OE8URQ	\N	\N	\N	t	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	180	VILLACH DOBRATSCH	dumb2	OE8
2196	repeater_voice	439	431.4	12.5	V	OE8XDK	46.758871	13.45896	0101000020110F00009B04E59284DC3641BB63490775845641	JN66RS	https://www.peakbagger.com/peak.aspx?pid=92976	2136.5	2129	\N	Spittal an der Drau	Goldeck	OE8OWK	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	178	GOLDECK	dumb2	OE8
2212	repeater_voice	145.7375	145.1375	12.5	V	OE8XPK	46.518507	14.772985	0101000020110F00003B2BEE2AE9173941AFBB9250665E5641	JN76IM	https://hamnetdb.net/?m=site&q=oe8xpk&as=-All-	1677.9	1700	\N	Bleiburg/Pliberk	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	t	Tone 1750. DTMF 1	\N	88.5	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	194	PETZEN (CTCSS 88.5 Hz)	dumb2	OE8
2213	repeater_voice	438.5	430.9	12.5	V	OE8XPK	46.518507	14.772985	0101000020110F00003B2BEE2AE9173941AFBB9250665E5641	JN76IM	https://hamnetdb.net/?m=site&q=oe8xpk&as=-All-	1677.9	1700	\N	Bleiburg/Pliberk	Petzen	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	195	PETZEN	dumb2	OE8
2218	repeater_voice	438.775	431.175	12.5	V	OE8XWZ	46.66441	14.25703	0101000020110F00007703E0518D37384130E0840F7B755641	JN76DP	Google Maps, Blumenweg 21	456.1	450	\N	Klagenfurt	Wölfnitz Ort	OE8LCK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	200	WÖLFNITZ KLAGENFURT	dumb2	OE8
2217	repeater_voice	438.95	431.35	12.5	V	OE8XWK	46.80088	14.43904	0101000020110F0000C2679194B286384150F6FA3D208B5641	JN76FT	Estimate Google Maps/Basemap Wolschartweg 53	620.3	583	\N	St Veit an der Glan	St. Georgen am Längsee Ort	OE1BAD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	199	ST.GEORGEN AM LÄNGSEE	dumb2	OE8
2229	repeater_voice	438.5	430.9	12.5	V	OE9XVJ	47.50601	9.7792	0101000020110F000040437A90679C3041B4D1D19DD9FB5641	JN47VM	https://hamnetdb.net/?q=oe9xpr	1023.5	1020	\N	Bregenz	Pfänder	OE9LTV	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	211	BREGENZ PFÄNDER	dumb2	OE9
2185	repeater_voice	145.6875	145.0875	12.5	V	OE7XVR	47.15761255	10.21305436	0101000020110F0000E3BCC302105931415FBE53A0F7C35641	JN57CD	OSM	2808.1	2809	\N	Arlberg	Valluga	OE7ERJ	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	167	ARLBERG – VALLUGA	dumb2	OE7
2244	packet_radio	438.275	430.675	12.5	V	OE7XLR	47.305572	11.377861	0101000020110F000011BE5DB1915333419ED53EA7A7DB5641	JN57QG	https://hamnetdb.net/?m=site&q=oe7xlr&as=-All-&tab=	1913.4	\N	\N	Innsbruck	Seegrube	OE7FMH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	Innsbruck-Seegrube	\N	OE7
2159	repeater_voice	1259.2	1294.2	12.5	V	OE7XBI	47.242985	11.181174	0101000020110F0000ED599D980AFE32413142477FA0D15641	JN57OF	https://hamnetdb.net/?m=site&q=oe7xbi&as=-All-	1938	1939	\N	Oberpferfuss	Rangger Köpl	OE7WSH	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02	141	OBERPFERFUSS RANGGER KÖPFL	dumb2	OE7
2156	repeater_voice	51.91	51.31	12.5	V	OE7XBI	47.242985	11.181174	0101000020110F0000ED599D980AFE32413142477FA0D15641	JN57OF	https://hamnetdb.net/?m=site&q=oe7xbi&as=-All-	1938	1939	\N	Oberpferfuss	Rangger Köpl	OE7NCI	\N	\N	\N	\N	\N	active	t	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling #oe7	2021-10-16 14:40:51.350258+02	138	RANGGER KÖPFL	dumb2	OE7
2223	repeater_voice	434.9	434.9	12.5	V	OE9XFV	47.49003	9.74761	0101000020110F0000EF814DFBAA8E3041CD4FD35E47F95641	JN47VL	Google Maps Gebhardsberg	595.9	550	\N	Bregenz	Gebhartsberg	OE9AFV	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	205	BREGENZ GEBHARDSBERG	dumb2	OE9
2228	repeater_voice	438.625	431.025	12.5	V	OE9XVI	47.20918	9.591069	0101000020110F00007A72D0EA984A3041DD5A502A37CC5641	JN47TF	https://hamnetdb.net/?m=site&q=oe9xvi&as=-All-&tab=	1314.7	1320	\N	Feldkirch	Vorderälpele	OE9PKV	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	210	FELDKIRCH VORDERÄLPELE	dumb2	OE9
2230	repeater_voice	438.875	431.275	12.5	V	OE9XVJ	47.50601	9.7792	0101000020110F000040437A90679C3041B4D1D19DD9FB5641	JN47VM	https://hamnetdb.net/?q=oe9xpr	1023.5	1020	\N	Bregenz	Pfänder	OE9HLH	\N	\N	\N	\N	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	212	BREGENZ PFÄNDER	dumb2	OE9
2232	repeater_voice	438.825	431.225	12.5	V	OE9XVV	47.22903	9.737786	0101000020110F0000726E0461658A30411FA0518364CF5641	JN47UF	https://hamnetdb.net/?m=site&q=oe9xvv&as=-All-&tab=	1333.1	1320	\N	Bludenz	Dünserberg	OE9TFH	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	214	DÜNSERBERG IM WALGAU	dumb2	OE9
2143	repeater_voice	438.65	431.05	12.5	V	OE6XEE	47.08036	14.95033	0101000020110F0000DE416F1F076539415D59E12FA0B75641	JN77LC	Estimate Google Maps Stubalpe	1326.8	1647	\N	Köflach	Stubalpe	OE6PZG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	125	STUBALPE	dumb2	OE6
2141	repeater_voice	438.675	431.075	12.5	V	OE6XDG	47.25505	14.34483	0101000020110F00005843CE2BBB5D3841C2CCCF228FD35641	JN77EG	https://hamnetdb.net/?m=site&q=oe6xar&as=-All-	1764.7	1902	\N	Judenburg	Klosterneuburgerhütte	OE6POD	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	123	KLOSTERNEUBURGERHÜTTE	dumb2	OE6
2065	repeater_voice	145.725	145.125	12.5	V	OE3XHW	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AT	Google Maps	917.8	1065	\N	Wr. Neustadt	Hohe Wand	OE3GWC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	47	WR.NEUSTADT HOHE WAND	dumb2	OE3
2278	beacon	70.045	\N	12.5	V	\N	48.39924	14.24318	0101000020110F0000170E7D8B873138415B9F9741D78C5741	JN78CJ	Google Maps, Eidenberger Almstraße 28	851.7	840	\N	Linz	Eidenberg	OE5MPL	\N	\N	\N	\N	\N	planned	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Linz/Eidenberg	\N	OE5
2284	beacon	5760.893	\N	12.5	V	OE1XGA	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG06	\N	483.4	480	\N	Wien	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Wien, Kahlenberg	\N	OE1
2288	beacon	10368.88	\N	12.5	V	OE1XGA	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG06	\N	483.4	480	\N	Wien	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Wien, Kahlenberg	\N	OE1
2291	beacon	24048.96	\N	12.5	V	OE1XGA	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG06	\N	483.4	480	\N	Wien	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Wien, Kahlenberg	\N	OE1
2279	beacon	432.4	\N	12.5	V	OE3XAC	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	707	\N	St. Pölten	Kaiserkogel	OE3KLU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Kaiserkogel	\N	OE3
2296	beacon	76032.875	\N	12.5	V	OE5XBM	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ29	\N	955.3	985	\N	Linz	Breitenstein	OE5VRL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Breitenstein	\N	OE5
2293	beacon	47088.8	\N	12.5	V	OE1XGA	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG06	\N	483.4	480	\N	Wien	Kahlenberg	OE4WOG	\N	\N	\N	\N	\N	planed	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	CW	\N	\N	2021-10-23 20:40:08.807978+02	\N	Wien, Kahlenberg	\N	OE1
2039	repeater_voice	438.45	430.85	12.5	V	OE1XUR	48.15508	16.39578	0101000020110F0000406479E191D93B41C3BD8860F5645741	KM88ED	Google Maps	249.8	325	\N	Wien	Laaerberg Schule	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	21	LAAERBERG/SCHULE	dumb2	OE1
2208	repeater_voice	438.85	431.25	12.5	V	OE8XMK	46.728051	14.429426	0101000020110F00001A80D15A84823841A1B69F5F917F5641	JN76FR	https://www.peakbagger.com/peak.aspx?pid=-60071	1059	1036	\N	Klagenfurt	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	190	KLAGENFURT MAGDALENSBERG	dumb2	OE8
2210	repeater_voice	145.7625	145.1625	12.5	V	OE8XNK	46.695	13.914167	0101000020110F0000338339FC75A2374154537DE8537A5641	JN66WQ	https://www.peakbagger.com/peak.aspx?pid=13706	1908.7	1897	\N	Villach	Gerlitzen	OE8RGQ	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	192	GERLITZE	dumb2	OE8
2071	repeater_voice	145.5875	144.9875	12.5	V	OE3XLU	48.09671	16.23893	0101000020110F0000E72D2B6B5D953B41DFC18DC2735B5741	JN88CC	Google Maps, Waldgasse 1	398.2	424	\N	Mödling	Gießhübel	OE3KLU	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	53	MÖDLING GIESZHÜBL	dumb2	OE3
2176	repeater_voice	438.65	431.05	12.5	V	OE7XLR	47.305572	11.377861	0101000020110F000011BE5DB1915333419ED53EA7A7DB5641	JN57QH	https://hamnetdb.net/?m=site&q=oe7xlr&as=-All-&tab=	1913.4	1945	\N	Innsbruck	Seegrube	OE7AAI	\N	\N	\N	\N	\N	active	t	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	coupling Südtirol	2021-10-16 14:40:51.350258+02	158	INNSBRUCK SEEGRUBE	dumb2	OE7
2178	repeater_voice	145.7	145.1	12.5	V	OE7XRT	47.478174	10.641632	0101000020110F0000A6EE310E6D133241006707215FF75641	JN57HL	https://www.peakbagger.com/peak.aspx?pid=95948	1906.4	1700	\N	Reutte	Hahnenkamm	OE7WRH	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	160	REUTTE HAHNENKAMM	dumb2	OE7
2179	repeater_voice	145.6125	145.0125	12.5	V	OE7XTI	47.208287	11.460929	0101000020110F0000C799C1C7B0773341F5C4009512CC5641	JN57RE	https://www.peakbagger.com/peak.aspx?pid=-43100	2242.8	2246	\N	Innsbruck	Patscherkofel	OE7DA	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	161	INNSBRUCK PATSCHERKOFEL	dumb2	OE7
2180	repeater_voice	145.7625	145.1625	12.5	V	OE7XTR	47.145919	10.626826	0101000020110F00007AEDEBDBFC0C3241D487151819C25641	JN57HD	https://www.peakbagger.com/peak.aspx?pid=-33295	2203.3	2200	\N	Landeck	Krahberg	OE7TTT	\N	\N	\N	\N	t	active	t	\N	\N	77	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	162	LANDECK KRAHBERG	dumb2	OE7
2181	repeater_voice	145.75	145.15	12.5	V	OE7XTT	47.168667	11.8	0101000020110F000065CFC9FD210B34413607021ABCC55641	JN57VE	https://hamnetdb.net/?m=site&q=oe7xtt&as=-All-&tab=	2085.6	2095	\N	Zillertal	Penkenjoch	OE7WWH	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	163	ZILLERTAL PENKENJOCH	dumb2	OE7
2161	repeater_voice	438.9	431.3	12.5	V	OE7XFI	47.357	11.755	0101000020110F0000331F419D90F733411EE43E5FE7E35641	JN57VI	https://hamnetdb.net/?m=site&q=oe7xfi&as=-All-&tab=	1107.9	1110	\N	Jenbach	Gallzein Kogelmoos	OE7WOT	\N	\N	\N	\N	t	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	143	JENBACH GALLZEIN KOGELMOOS	dumb2	OE7
2155	repeater_voice	439.025	431.425	12.5	V	OE6XVE	47.08036	14.95033	0101000020110F0000DE416F1F076539415D59E12FA0B75641	JN77LC	Estimate Google Maps Stubalpe	1326.8	1647	\N	Köflach	Stubalpe	OE6PZG	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	137	STUBALPE	dumb2	OE6
2174	repeater_voice	439.075	431.475	12.5	V	OE7XLI	46.82166	12.70025	0101000020110F0000CB1CEA5C9992354104CCDB376D8E5641	JN66IT	Approx Gmaps	2018.9	2023	\N	Lienz	Hochstein	OE7JTK	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	156	LIENZ HOCHSTEIN	dumb2	OE7
2097	repeater_voice	145.7625	145.1625	12.5	V	OE3XWW	47.510703	16.037665	0101000020110F0000764189B3D83D3B41843CCEF79AFC5641	JN87AM	https://hamnetdb.net/?m=site&q=oe3xww&as=-All-	947.6	1002	\N	Mönichkirchen	Ort	OE3RPU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	79	MÖNICHKIRCHEN	dumb2	OE3
2166	repeater_voice	438.05	430.45	12.5	V	OE7XIH	47.183272	11.281548	0101000020110F0000EE95C02DB0293341D0A4FA0C12C85641	JN57RF	https://www.peakbagger.com/peak.aspx?pid=30545	2336.2	2346	\N	Innsbruck	Hoadl	OE7MBT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	148	INNSBRUCK HOADL	dumb2	OE7
2091	repeater_voice	438.275	430.675	12.5	V	OE3XVI	47.93742	15.81881	0101000020110F000061A8C8DFADDE3A412729D88390415741	JN77VW	https://www.peakbagger.com/peak.aspx?pid=76519	1320.2	1329	\N	Pernitz	Unterberg	OE1AOA	\N	\N	\N	\N	t	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	73	UNTERBERG GUTENSTEINER ALPEN	dumb2	OE3
2169	repeater_voice	438.4	430.8	12.5	V	OE7XKT	47.29529	11.87464	0101000020110F0000E9A9CEE0962B3441E11831B401DA5641	JN57WH	https://hamnetdb.net/?m=site&q=oe7xkt&as=-All-	553.3	545	\N	Zillertal	Kaltenbach	OE7SBH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	151	KALTENBACH	dumb2	OE7
2107	repeater_voice	438.425	430.825	12.5	V	OE5XDN	48.27889	13.40661	0101000020110F00005B569BFFC0C53641AE2B8E8F28795741	JN68QG	Google Maps, Wolfau 5	476.4	482	\N	Ried im Innkreis	Senftenbach/Wolfau	OE5RLN	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	89	RIED-GRIESKIRCHEN SENFTENBACH	dumb2	OE5
2118	repeater_voice	438.5	430.9	12.5	V	OE5XKL	47.524287	13.69208	0101000020110F000004BF9D5FE3413741C7D0DAB9CAFE5641	JN67UM	https://www.peakbagger.com/peak.aspx?pid=61502	2106	2100	\N	Obertraun	Krippenstein	OE5VFM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	100	KRIPPENSTEIN	dumb2	OE5
2042	repeater_voice	438.525	430.925	12.5	V	OE2XGR	47.30755	13.238225	0101000020110F000079384C77887C36415ABBD2D5F8DB5641	JN67OH	https://www.peakbagger.com/peak.aspx?pid=-76414	1785.5	1780	\N	St. Johann im Pongau	Gernkogel	OE2HFO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	24	ST.JOHANN I P GERNKOGEL	dumb2	OE2
2095	repeater_voice	1298.6	1270600	12.5	V	OE3XWW	47.510703	16.037665	0101000020110F0000764189B3D83D3B41843CCEF79AFC5641	JN87AM	https://hamnetdb.net/?m=site&q=oe3xww&as=-All-	947.6	1002	\N	Mönichkirchen	Ort	OE3RPU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	A	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	77	MÖNICHKIRCHEN	dumb2	OE3
2183	repeater_voice	438.55	430.95	12.5	V	OE7XTT	47.168667	11.8	0101000020110F000065CFC9FD210B34413607021ABCC55641	JN57VE	https://hamnetdb.net/?m=site&q=oe7xtt&as=-All-&tab=	2085.6	2095	\N	Zillertal	Penkenjoch	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	165	ZILLERTAL PENKENJOCH	dumb2	OE7
2069	repeater_voice	438.2	430.6	12.5	V	OE3XKV	47.710833	14.901111	0101000020110F00005EE5B916A04F394149A8A077E01C5741	JN77KR	https://www.peakbagger.com/peak.aspx?pid=14009	1807.4	1808	\N	Waidhofen an der Ybbs	Hochkar	OE3CDW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	51	HOCHKAR	dumb2	OE3
2073	repeater_voice	438.225	430.625	12.5	V	OE3XNK	47.8346	16.04605	0101000020110F00008A97801D7E413B41F57A6289E5305741	JN87AU	Google Maps	917.8	841	\N	Wr. Neustadt	Hohe Wand	OE3GBB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	55	WIENER NEUSTADT HOHE WAND	dumb2	OE3
2092	repeater_voice	438.425	430.825	12.5	V	OE3XWJ	48.33373	15.3332	0101000020110F000014BE2704840B3A41D4D8A7121F825741	JN78QI	Google Maps	942.5	960	\N	Spitz an der Donau	Jauerling	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	74	JAUERLING	dumb2	OE3
2163	repeater_voice	439.025	431.425	12.5	V	OE7XFJ	47.48446	12.42795	0101000020110F0000E970CB10311C354190DF90FA61F85641	JN67FL	https://hamnetdb.net/?m=site&q=oe7xfj&as=-All-&tab=	1601.1	1600	\N	St. Johann in Tirol	Harschbichl	OE7GBJ	\N	\N	\N	\N	\N	active	t	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	145	ST.JOHANN/TIROL HARSCHBICHL	dumb2	OE7
2170	repeater_voice	438.5	430.9	12.5	V	OE7XLH	46.83869	12.84436	0101000020110F00007045619D43D13541555AA6F321915641	\N	Community Gmaps	1130.5	1349	\N	Lienz	Iselsberg-Stronach	OE7JTK	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	152	ISELSBERG STRONACH	dumb2	OE7
2177	repeater_voice	438.875	431.275	12.5	V	OE7XOI	47.07803	10.59878	0101000020110F000094CBE9CACA00324150C08BF740B75641	JN57HC	https://hamnetdb.net/?m=site&q=oe7xoi&as=-All-&tab=	2488.8	2540	\N	\N	Schönjöchl	OE7SJJ	\N	\N	\N	t	\N	active	t	Tone 1750	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	159	FISS ZWÖLFERKOPFBAHN	dumb2	OE7
2263	packet_radio	\N	\N	12.5	V	OE1XAB	48.1899867	16.3404457	0101000020110F0000C8943B1882C13B4110352F10A66A5741	\N	OSM	182.3	\N	\N	Wien	Eisvogelgasse	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	Eisvogelgasse	\N	OE1
2167	repeater_voice	438.5	430.9	12.5	V	OE7XKH	47.145919	10.626826	0101000020110F00007AEDEBDBFC0C3241D487151819C25641	JN57HD	https://www.peakbagger.com/peak.aspx?pid=-33295	2203.3	2212	\N	Landeck	Krahberg	OE7ERJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	149	LANDECK KRAHBERG	dumb2	OE7
2128	repeater_voice	438.6	431	12.5	V	OE6XAG	47.198505	15.465789	0101000020110F00002D1396C12B453A415F2BE4E281CA5641	JN77RE	https://www.peakbagger.com/peak.aspx?pid=89381	1444.3	144.5	\N	Graz	Schöckl	OE6DJG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	110	GRAZ SCHÖCKL	dumb2	OE6
2130	repeater_voice	438.425	430.825	12.5	V	OE6XAR	47.25505	14.34483	0101000020110F00005843CE2BBB5D3841C2CCCF228FD35641	JN77EG	https://hamnetdb.net/?m=site&q=oe6xar&as=-All-	1764.7	1902	\N	Judenburg	Klosterneuburgerhütte	OE6POD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	112	SCHÖNBERG	dumb2	OE6
2131	repeater_voice	438.9125	431.3125	12.5	V	OE6XBF	46.845678	15.931635	0101000020110F0000077AE67EBD0F3B41B07B95443E925641	JN76XU	https://www.peakbagger.com/peak.aspx?pid=95413	607.9	608	\N	Bad Gleichenberg	Stradner Kogel	OE6JWD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	113	HOCHSTRADEN STRADNER KOGEL	dumb2	OE6
2134	repeater_voice	438.925	431.325	12.5	V	OE6XBG	47.40554	15.35936	0101000020110F000013125522E4163A41E620C564B2EB5641	JN77QJ	https://hamnetdb.net/?m=site&q=oe6xbg&as=-All-&tab=	1618	1630	\N	Bruck an der Mur	Rennfeld	OE6MKD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	116	BRUCK A D.MUR RENNFELD	dumb2	OE6
2147	repeater_voice	438.35	430.75	12.5	V	OE6XIG	47.43786	15.19713	0101000020110F00008023EBC558D03941801CA2C8E3F05641	JN77OJ	Estimate Google Maps, Brandmeister Map	761.7	722	\N	Bruck an der Mur	Oberaich	OE6JFG	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	129	BRUCK/MUR OBERAICH	dumb2	OE6
2150	repeater_voice	438.525	430.925	12.5	V	OE6XME	47.50585	15.44903	0101000020110F0000962D2127E23D3A4140AF5806D3FB5641	JN77PK	Estimate Google Maps (Brandmeister)	568.3	561	\N	Bruck an der Mur	Kindberg Ort	OE6JFG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	132	BRUCK AN DER MUR	dumb2	OE6
2034	repeater_voice	2401.9	2449.9	12.5	V	OE1XKU	48.215096	16.261484	0101000020110F0000ACF7501E2C9F3B41340B5D82BE6E5741	JN88EE	https://www.peakbagger.com/peak.aspx?pid=-80350	432.2	240	\N	Wien 	Satzberg	OE1MCU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	16	WIEN WIENERBERG	dumb2	OE1
2040	repeater_voice	438.95	431.35	12.5	V	OE1XUU	48.276145	16.333217	0101000020110F000043C042665DBE3B4119B53EC6B5785741	JN88EG	https://www.peakbagger.com/peak.aspx?pid=10141	483.4	540	\N	Wien	Kahlenberg	OE1BAD	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	22	WIEN KAHLENBERG	dumb2	OE1
2043	repeater_voice	51.85	51.25	12.5	V	OE2XHL	47.188104	12.687513	0101000020110F0000845C917C0F8D35416D446EEAD7C85641	JN67IE	https://www.peakbagger.com/peak.aspx?pid=10110	3196.8	3035	\N	Zell am See	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	inactive	2021-10-16 14:40:51.350258+02	25	KITZSTEINHORN	dumb2	OE2
2044	repeater_voice	145.65	145.05	12.5	V	OE2XHL	47.188104	12.687513	0101000020110F0000845C917C0F8D35416D446EEAD7C85641	JN67IE	https://www.peakbagger.com/peak.aspx?pid=10110	3196.8	3035	\N	Zell am See	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	26	KITZSTEINHORN	dumb2	OE2
2046	repeater_voice	145.7625	145.1625	12.5	V	OE2XJL	47.30755	13.238225	0101000020110F000079384C77887C36415ABBD2D5F8DB5641	JN67OH	https://www.peakbagger.com/peak.aspx?pid=-76414	1785.5	1780	\N	St. Johann im Pongau	Gernkogel	OE2HFO	\N	\N	\N	\N	\N	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	28	ST.JOHANN IM PONGAU GERNKOGEL	dumb2	OE2
2189	repeater_voice	438.2	430.6	12.5	V	OE7XXR	47.46738	11.82695	0101000020110F00009B1D380DDA1634416CADB4B7A2F55641	JN57VK	Google Maps	1920.6	1943	\N	Kramsach	Rofan Roßkogel	OE7SRI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	171	ROFAN ROSSKOGEL	dumb2	OE7
2231	repeater_voice	438.2	430.6	12.5	V	OE9XVJ	47.50601	9.7792	0101000020110F000040437A90679C3041B4D1D19DD9FB5641	JN47VM	https://hamnetdb.net/?q=oe9xpr	1023.5	1020	\N	Bregenz	Pfänder	OE9HLH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	213	BREGENZ PFÄNDER	dumb2	OE9
2209	repeater_voice	438.425	430.825	12.5	V	OE8XMK	46.728051	14.429426	0101000020110F00001A80D15A84823841A1B69F5F917F5641	JN76FR	https://www.peakbagger.com/peak.aspx?pid=-60071	1059	1036	\N	Klagenfurt	Magdalensberg	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	191	KLAGENFURT MAGDALENSBERG	dumb2	OE8
2175	repeater_voice	438.575	430.975	12.5	V	OE7XLI	46.82166	12.70025	0101000020110F0000CB1CEA5C9992354104CCDB376D8E5641	JN66IT	Approx Gmaps	2018.9	2023	\N	Lienz	Hochstein	OE7JTK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	157	LIENZ HOCHSTEIN	dumb2	OE7
2138	repeater_voice	438.9	431.3	12.5	V	OE6XDE	47.090608	15.385301	0101000020110F0000F6517EDF2B223A413CA98F0A43B95641	JN76QC	https://www.peakbagger.com/peak.aspx?pid=95412	752.9	754	\N	Graz	Plabutsch	OE6THH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	120	PLABUTSCH	dumb2	OE6
2193	repeater_voice	438.975	431.375	12.5	V	OE7XZT	47.13717	11.86928	0101000020110F000087A0A73442293441CE603A21B3C05641	JN57WD	https://hamnetdb.net/?m=site&q=oe7xzt&as=-All-&tab=	1952.4	1900	\N	Mayhofen	Ahorn	OE7BKH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	175	MAYRHOFEN AHORNBAHN	dumb2	OE7
2030	repeater_voice	145.625	145.025	12.5	V	OE1XFW	48.157173	16.396717	0101000020110F00005A30E72FFAD93B41DC6D1AB14C655741	JN88ED	https://www.peakbagger.com/peak.aspx?pid=10144	251.7	317	\N	Wien	Laaerberg	OE3NSC	\N	\N	\N	\N	t	active	t	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	13	WIEN (LINK R70) LAAERBERG	dumb2	OE1
2028	repeater_voice	438.3375	430.7375	12.5	V	OE1XDT	48.24052	16.4099	0101000020110F0000FA9143B6B5DF3B415550A09EE4725741	JN88EF	Google Maps	165.3	165	\N	Wien	Donauturm	OE1KBC	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	11	WIEN DONAUTURM	dumb2	OE1
2036	repeater_voice	438.825	431.225	12.5	V	OE1XQU	48.16803	16.3454	0101000020110F0000D7FBD49AA9C33B418BE004AD11675741	JN88EE	https://hamnetdb.net/?m=as&q=oe1xca&tab=	222.5	240	\N	Wien	Wienerberg	OE1MCU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	18	WIEN WIENERBERG	dumb2	OE1
2047	repeater_voice	145.6125	145.0125	12.5	V	OE2XNL	47.127031	13.624763	0101000020110F0000B729E9AD9D24374107B0145E14BF5641	JN67TC	https://www.peakbagger.com/peak.aspx?pid=62340	2388.4	2411	\N	Lungau	Speiereck	OE2TRM	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	29	SPEIERECK LUNGAU	dumb2	OE2
2031	repeater_voice	438.65	431.05	12.5	V	OE1XFW	48.157173	16.396717	0101000020110F00005A30E72FFAD93B41DC6D1AB14C655741	JN88ED	https://www.peakbagger.com/peak.aspx?pid=10144	251.7	317	\N	Wien	Laaerberg	OE3NSC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	14	WIEN (LINK R1)	dumb2	OE1
2038	repeater_voice	430.4875	430.4875	12.5	V	OE1XTW	48.18185	16.3908	0101000020110F0000D9547B8267D73B410A83566C52695741	JN88EE	Google Maps	197.9	350	\N	Wien	Arsenal Funkturm	OE1ERR	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	20	WIEN ARSENAL FUNKTURM	dumb2	OE1
2045	repeater_voice	438.825	431.225	12.5	V	OE2XHM	47.420263	13.062393	0101000020110F0000C1FFF2EF12303641D61670E10FEE5641	JN67MK	https://www.peakbagger.com/peak.aspx?pid=10019	2938.9	2941	\N	Bischofshofen	Hochköngi Matrashaus	OE2WCL	\N	\N	\N	t	\N	active	t	Tone 1750. DTMF 1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	27	HOCHKÖNIG MATRASHAUS	dumb2	OE2
2035	repeater_voice	145.75	145.15	12.5	V	OE3XQA	48.24876033	16.2440474	0101000020110F000039E4C11597973B41C415E6FA3C745741	JN88CF	OSM	514.8	577	\N	Wien	Exelberg	OE1BAD	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	17	WIEN EXELBERG	dumb2	OE3
2235	packet_radio	\N	\N	12.5	V	OE7XVR	47.15761255	10.21305436	0101000020110F0000E3BCC302105931415FBE53A0F7C35641	\N	OSM	2808.1	\N	\N	Arlberg	Valluga	OE7ERJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-21 12:45:40.647422+02	\N	Valuga	\N	OE7
2064	repeater_voice	438.975	431.375	12.5	V	OE3XFW	48.15183	16.03118	0101000020110F000045CD5ECB063B3B41510E62CD6D645741	JN78XD	Estimate, Google Maps, Jochgrabengerg	573.5	590	\N	Pressbaum	Jochgrabenberg	OE3ARC	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	46	HOCHSTRASZ	dumb2	OE3
2060	repeater_voice	439.05	431.45	12.5	V	OE3XEB	48.223986	16.110077	0101000020110F00007FD37A91555D3B41B88743D631705741	JN88BF	https://www.peakbagger.com/peak.aspx?pid=-87572	540.2	542	\N	Purkersdorf	Troppberg	OE1NHU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	42	TROPPBERGWARTE	dumb2	OE3
2172	repeater_voice	438.3	430.7	12.5	V	OE7XLI	46.82166	12.70025	0101000020110F0000CB1CEA5C9992354104CCDB376D8E5641	JN66IT	Approx Gmaps	2018.9	2057	\N	Lienz	Hochstein	OE7NGI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	154	LIENZ HOCHSTEIN	dumb2	OE7
2054	repeater_voice	438.55	430.95	12.5	V	OE2XZR	47.805128	13.112955	0101000020110F0000066C30790F4636411387E905202C5741	JN67NT	https://www.peakbagger.com/peak.aspx?pid=96034	1281	1263	\N	Salzburg	Gaisberg	OE2RPL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	36	SALZBURG GAISBERG	dumb2	OE2
2068	repeater_voice	438.5	430.9	12.5	V	OE3XKC	48.03663	15.43243	0101000020110F0000944FD23FAA363A4149194DBBAD515741	JN78RA	Estimate Google Maps, Kirchberggegend 9	516.2	51.5	\N	Kirchberg an der Pielach	Fronberg	OE3ICU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	50	PIELACHTAL KIRCHBERG	dumb2	OE3
2221	repeater_voice	438.65	431.05	12.5	V	OE9XDV	\N	\N	\N	JN47TE	nicht in RufzL	\N	1010	\N	Feldkirch	Bazora	OE9VVV	\N	\N	\N	\N	\N	historic	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	203	FELDKIRCH BAZORA	dumb2	\N
2225	repeater_voice	145.7	145.1	12.5	V	OE9XMV	\N	\N	\N	JN47TF	nicht in RufzL	\N	530	\N	Feldkirch	Frastanz	OE9VVV	\N	\N	\N	\N	\N	historic	t	\N	\N	123	\N	\N	\N	\N	t	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	207	FELDKIRCH FRASTANZ	dumb2	\N
2086	repeater_voice	145.7	145.1	12.5	V	OE3XSA	48.43338	15.471389	0101000020110F0000A84E35259B473A41640105C46E925741	JN78RL	https://hamnetdb.net/?q=oe3xsa	696.8	710	\N	Krems	Sandl	OE3WLS	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	68	KREMS SANDL	dumb2	OE3
2088	repeater_voice	438.775	431.175	12.5	V	OE3XSA	48.43338	15.471389	0101000020110F0000A84E35259B473A41640105C46E925741	JN78RL	https://hamnetdb.net/?q=oe3xsa	696.8	710	\N	Krems	Sandl	OE3WLS	\N	\N	\N	\N	\N	active	t	\N	\N	162.2	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	70	KREMS SANDL	dumb2	OE3
2037	repeater_voice	438.25	430.65	12.5	V	OE1XTK	48.21688	16.2259	0101000020110F00000139F8ECB28F3B4193522D05096F5741	JN88CF	Google Maps, Viktor Hagl G 13	255.4	243	\N	Wien	Hadersdorf	OE1TKS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	19	WIEN AUHOF	dumb2	OE1
2211	repeater_voice	145.65	145.05	12.5	V	OE8XOK	46.76179	13.45725	0101000020110F0000B49FAC37C6DB3641FB0E819CEB845641	JN66RS	Estimate Google Maps Bergstation	2048.5	2020	\N	Spittal an der Drau	Goldeck	OE8HAK	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	193	SPITTAL - GOLDECK	dumb2	OE8
2247	packet_radio	438.325	430.725	12.5	V	OE7XLR	47.305572	11.377861	0101000020110F000011BE5DB1915333419ED53EA7A7DB5641	JN57QG	https://hamnetdb.net/?m=site&q=oe7xlr&as=-All-&tab=	1913.4	\N	\N	Innsbruck	Seegrube	OE7FMH	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	Innsbruck-Seegrube	\N	OE7
2142	repeater_voice	145.7	145.1	12.5	V	OE6XDG	47.25505	14.34483	0101000020110F00005843CE2BBB5D3841C2CCCF228FD35641	JN77EG	https://hamnetdb.net/?m=site&q=oe6xar&as=-All-	1764.7	1902	\N	Judenburg	Klosterneuburgerhütte	OE6POD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	C	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	124	JUDENBURG KLOSTERNEUBURGERHÜTTE	dumb2	OE6
2248	packet_radio	433.675	433.675	12.5	V	OE3XBR	48.223986	16.110077	0101000020110F00007FD37A91555D3B41B88743D631705741	JN88BF	https://www.peakbagger.com/peak.aspx?pid=-87572	540.2	\N	\N	Purkersdorf	Troppberg	OE1NHU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Troppberg	\N	OE3
2077	repeater_voice	438.325	430.725	12.5	V	OE3XNR	48.672816	14.77828	0101000020110F000062FCB99A361A394181287D97C1B95741	JN78JQ	GPS, Sysop	1005.4	1017	\N	Weitra	Nebelstein	OE3IGW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	59	NEBELSTEIN	dumb2	OE3
2184	repeater_voice	438.625	431.025	12.5	V	OE7XUT	47.52365	12.57709	0101000020110F0000115E24410B5D3541A2D34A79B0FE5641	\N	Google Maps Ortsstraße 98	848.9	849	\N	Saalfelden	St. Ulrich am Pillersee Ort	OE7MFI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	166	ST. ULRICH AM PILLERSEE	dumb2	OE7
2055	repeater_voice	439	431.4	12.5	V	OE2XZR	47.805128	13.112955	0101000020110F0000066C30790F4636411387E905202C5741	JN67NT	https://www.peakbagger.com/peak.aspx?pid=96034	1281	1263	\N	Salzburg	Gaisberg	OE2AIP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	37	SALZBURG GAISBERG	dumb2	OE2
2080	repeater_voice	438.45	430.85	12.5	V	OE3XPA	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	OSM https://hamnetdb.net/?m=site&q=oe3xpa&as=-All-	711.5	726	\N	St. Pölten	Kaiserkogel	OE3CJB	https://oe3.oevsv.at/adl304/umsetzer/umsetzer/	\N	t	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	t	B	\N	\N	\N	\N	\N	cjb confirmed	2021-10-16 14:40:51.350258+02	62	ST. PÖLTEN-KAISERKOGEL	dumb2	OE3
2237	packet_radio	144.825	144.825	12.5	V	OE1XAR	48.3106475	16.3827774	0101000020110F0000A5541D70EAD33B41F64872FF587E5741	JN88EH	OSM	305.7	\N	\N	Wien	Bisamberg	OE1NHU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Bisamberg	\N	OE1
2239	packet_radio	144.95	144.95	12.5	V	OE3XOR	\N	\N	\N	JN78VA	\N	\N	\N	\N	\N	Hainfelder Hütte	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Hainfelder Hütte	\N	\N
2243	packet_radio	144.875	144.875	12.5	V	OE7XPR	\N	\N	\N	JN57JE	\N	\N	\N	\N	\N	Sechszeiger	OE7HNT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Sechszeiger	\N	\N
2249	packet_radio	433.675	433.675	12.5	V	OE3XOR	\N	\N	\N	JN78VA	\N	\N	\N	\N	\N	Hainfelder Hütte	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Hainfelder Hütte	\N	\N
2250	packet_radio	438.55	438.55	12.5	V	OE3XPA	48.05978708	15.53965351	0101000020110F00005BB3DA504A653A419723D8C271555741	JN78SB	\N	711.5	\N	\N	St. Pölten	Kaiserkogel	OE3CJB	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps/FSK 9k6bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Kaiserkogel	\N	OE3
2112	repeater_voice	438.2625	430.6625	12.5	V	OE5XGL	47.8981318	13.8219805	0101000020110F0000B85EBDD45F7A3741BA690513313B5741	JN67VV	https://www.peakbagger.com/peak.aspx?pid=-76602	976.6	965	\N	Gmunden	Grünberg	OE5RDL	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	94	GMUNDEN GRÜNBERG	dumb2	OE5
2124	repeater_voice	438.525	430.925	12.5	V	OE5XOL	48.4152993	14.27429015	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	JN78DJ	https://hamnetdb.net/?m=site&q=oe5xol&as=-All-&tab=	955.3	955	\N	Linz	Breitenstein	OE5PON	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	conf	2021-10-16 14:40:51.350258+02	106	LINZ BREITENSTEIN	dumb2	OE5
2251	packet_radio	438.1	438.1	12.5	V	OE5XSO	\N	\N	\N	JN68SB	\N	\N	\N	\N	\N	Zell am Pettenfirst	OE5FHM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Zell am Pettenfirst	\N	\N
2252	packet_radio	438.475	438.475	12.5	V	OE6XFE	\N	\N	\N	JN76OT	\N	\N	\N	\N	\N	Wolfgangi	OE6RKE	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Wolfgangi	\N	\N
2254	packet_radio	438.525	430.925	12.5	V	OE7XHR	\N	\N	\N	JN57PE	\N	\N	\N	\N	\N	Axams / Hoadl	OE7MBT	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Axams / Hoadl	\N	\N
2257	packet_radio	144.925	144.925	12.5	V	OE9XFR	\N	\N	\N	JN47SF	\N	\N	\N	\N	\N	Schellenberg	OE9WLJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Schellenberg	\N	\N
2258	packet_radio	438.35	144.85	12.5	V	OE5XBR	\N	\N	\N	JN78DH	\N	\N	\N	\N	\N	Linz Froschberg	OE5AJP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps		\N	2021-10-21 12:45:40.647422+02	\N	Linz Froschberg	\N	\N
2260	packet_radio	430.4	430.4	12.5	V	OE9XFR	\N	\N	\N	JN47SF	\N	\N	\N	\N	\N	Schellenberg	OE9WLJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Schellenberg	\N	\N
2261	packet_radio	438	438	12.5	V	OE9XFR	\N	\N	\N	JN47SF	\N	\N	\N	\N	\N	Schellenberg	OE9WLJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	FSK 9k6bps	Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Schellenberg	\N	\N
2266	packet_radio	144.85	144.85	12.5	V	OE5XBR	\N	\N	\N	JN78DH	\N	\N	\N	\N	\N	Linz Froschberg	OE5AJP	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	Linz Froschberg	\N	\N
2259	packet_radio	438.2	438.2	12.5	V	OE5XUL	48.20026	13.58142	0101000020110F0000E5DB36C2C4113741232B37F7526C5741	JN68SE	\N	565	\N	\N	Ried	Geiersberg	OE5FHM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Ried Geiersberg	\N	OE5
2264	packet_radio	\N	\N	12.5	V	OE6XPE	46.91079	15.2744	0101000020110F00009DCD1F6EF2F139416B117B37999C5641	\N	Rougth estimate, Google Maps Pichling	355	\N	\N	Stainz	Pichling	OE6PWD	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	Graz	\N	OE6
2253	packet_radio	438	430.4	12.5	V	OE7XGR	47.064977	11.679196	0101000020110F000055EBCE269AD63341CCD3789B2BB55641	JN57UB	https://www.peakbagger.com/peak.aspx?pid=-56014	3246.8	\N	\N	Hintertux	Gefrorene Wand	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Gefrohrene Wand	\N	OE7
2104	repeater_voice	438.3	430.7	12.5	V	OE5XBN	48.24392	13.0286	0101000020110F000081D0241E61213641B5049CB272735741	JN68MF	Google Maps, Osternbergstra 55	355.6	355	\N	Braunau am Inn	Ort	OE5MCM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	B	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	86	BRAUNAU AM INN	dumb2	OE5
2238	packet_radio	144.725	144.725	12.5	V	OE2XMR	47.127031	13.624763	0101000020110F0000B729E9AD9D24374107B0145E14BF5641	JN67TD	\N	2388.4	\N	\N	Lungau	Speiereck	OE2VPK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Speiereck	\N	OE2
2245	packet_radio	433.675	433.675	12.5	V	OE1XAR	48.3106475	16.3827774	0101000020110F0000A5541D70EAD33B41F64872FF587E5741	JN88EH	OSM	305.7	\N	\N	Wien	Bisamberg	OE1NHU	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Bisamberg	\N	OE1
2246	packet_radio	438.125	430.525	12.5	V	OE1XUR	48.15508	16.39578	0101000020110F0000406479E191D93B41C3BD8860F5645741	JN88ED	Google Maps	249.8	\N	\N	Wien	Laaerberg Schule	OE1TKW	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	\N	\N	2021-10-21 12:45:40.647422+02	\N	Laaerberg	\N	OE1
2154	repeater_voice	439.1	431.5	12.5	V	OE6XRE	47.505327	14.93429	0101000020110F00006883E38E0D5E39410450747ABDFB5641	JN77LM	Google Maps, Eisenerzer Reichenstein	1849.7	2128	\N	Leoben	Eisenerzer Reichenstein	OE6SWG	\N	\N	\N	t	t	active	t	\N	\N	103.5	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	136	REICHENSTEIN	dumb2	OE6
2265	packet_radio	144.9	144.9	12.5	V	OE5XBL	\N	\N	\N	JN68PC	\N	\N	\N	\N	\N	St. Johann am Walde	OE5HPM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2/2k4bps	Mailbox	\N	2021-10-21 12:45:40.647422+02	\N	St. Johann am Walde	\N	\N
2267	packet_radio	438.325	430.725	12.5	V	OE2XGR	47.30755	13.238225	0101000020110F000079384C77887C36415ABBD2D5F8DB5641	JN67OH	https://www.peakbagger.com/peak.aspx?pid=-76414	1785.5	\N	\N	St. Johann im Pongau	Gernkogel	OE2WIO	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox,Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Gernkogel	\N	OE2
2268	packet_radio	438.025	430.425	12.5	V	OE2XWR	47.188104	12.687513	0101000020110F0000845C917C0F8D35416D446EEAD7C85641	JN67IE	https://www.peakbagger.com/peak.aspx?pid=10110	3196.8	\N	\N	Zell am See	Kitzsteinhorn	OE2FKM	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	AFSK 1k2bps FSK 4k8/9k6bps	Mailbox,Winlink	\N	2021-10-21 12:45:40.647422+02	\N	Kitzsteinhorn	\N	OE2
2236	packet_radio	\N	\N	12.5	V	OE7XZR	47.4211969	10.9843067	0101000020110F0000DE2EB66D6FA8324123B50E4B36EE5641	\N	https://hamnetdb.net/?m=site&q=oe7xzr&as=-All-&tab=	2935.7	\N	\N	Ehrwald	Zugspitze Ö	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-21 12:45:40.647422+02	\N	Zugspitze	\N	OE7
2153	repeater_voice	145.675	145.075	12.5	V	OE6XPG	47.369088	13.726221	0101000020110F0000B403A7EEBB50374100122506D8E55641	JN67UI	https://www.peakbagger.com/peak.aspx?pid=-74513	1904.7	1821	\N	Schladming	Planai	OE6SFG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	135	SCHLADMING-PLANAI	dumb2	OE6
2053	repeater_voice	145.6875	145.0875	12.5	V	OE2XZR	47.805128	13.112955	0101000020110F0000066C30790F4636411387E905202C5741	JN67NT	https://www.peakbagger.com/peak.aspx?pid=96034	1281	1263	\N	Salzburg	Gaisberg	OE2AIP	\N	\N	\N	\N	t	active	t	\N	\N	88.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	35	SALZBURG GAISBERG	dumb2	OE2
2148	repeater_voice	145.775	145.175	12.5	V	OE6XLG	47.08036	14.95033	0101000020110F0000DE416F1F076539415D59E12FA0B75641	JN77LC	Estimate Google Maps Stubalpe	1326.8	1647	\N	Köflach	Stubalpe	OE6PZG	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	130	STUBALPE	dumb2	OE6
2041	repeater_voice	430.5625	430.5625	12.5	V	OE1XZS	48.20296	16.29932	0101000020110F00003C6AAF00A0AF3B4126A3F1B3C36C5741	JN88DE	Google Maps/Breitenseerstraße 61 (Kaserne)	249	270	\N	Wien	Penzing/Breitenseerstraße	OE1AZS	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	23	WIEN PENZING	dumb2	OE1
2078	repeater_voice	438.8	431.2	12.5	V	OE3XNS	48.577044	16.39555	0101000020110F00009589FB4678D93B413F693B3E01AA5741	JN88EN	https://www.peakbagger.com/peak.aspx?pid=76538	490	485	\N	Mistelbach	Buschberg	OE3NSU	\N	\N	\N	\N	t	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	60	MISTELBACH BUSCHBERG	dumb2	OE3
2072	repeater_voice	439.025	431.425	12.5	V	OE3XLU	48.09671	16.23893	0101000020110F0000E72D2B6B5D953B41DFC18DC2735B5741	JN88CC	Google Maps, Waldgasse 1	398.2	424	\N	Mödling	Gießhübel	OE3KLU	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	54	MÖDLING GIESZHÜBL	dumb2	OE3
2048	repeater_voice	438.975	431.375	12.5	V	OE2XNM	47.127031	13.624763	0101000020110F0000B729E9AD9D24374107B0145E14BF5641	JN67TC	https://www.peakbagger.com/peak.aspx?pid=62340	2388.4	2411	\N	Lungau	Speiereck	OE2TRM	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	30	MAUTERNDORF SPEIERECKGIPFEL	dumb2	OE2
2164	repeater_voice	145.7875	145.1875	12.5	V	OE7XGI	46.88041	11.08384	0101000020110F0000C0EDC16CB7D33241D76758EFC3975641	JN56NV	Google Maps, Wurmkogel Lift Bergstation	3020.3	3082	\N	Sölden	Wurmkogel Lift	OE7ABT	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	146	ÖTZTAL WURMKOGEL	dumb2	OE7
2165	repeater_voice	438.925	431.325	12.5	V	OE7XGR	47.064977	11.679196	0101000020110F000055EBCE269AD63341CCD3789B2BB55641	JN57UB	https://www.peakbagger.com/peak.aspx?pid=-56014	3246.8	3255	\N	Hintertux	Gefrorene Wand	OE7FMI	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	147	HINTERTUX GEFRORENE WAND	dumb2	OE7
2168	repeater_voice	145.775	145.175	12.5	V	OE7XKI	47.465	12.204167	0101000020110F0000D15BEFA7E1BA3441D28186BD40F55641	JN67CL	https://www.peakbagger.com/peak.aspx?pid=13648	1828	1828	\N	Kufstein	Hohe Salve	OE7SLI	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	150	KUFSTEIN HOHE SALVE	dumb2	OE7
2139	repeater_voice	1298.05	1270050	12.5	V	OE6XDF	46.94991	15.37989	0101000020110F00005624F485D11F3A4175C6117CD3A25641	JN76QW	https://hamnetdb.net/?q=oe6xpd	348.5	350	\N	Graz	Dobl	OE6THH	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	121	GRAZ-DOBL	dumb2	OE6
2144	repeater_voice	438.2	430.6	12.5	V	OE6XFD	46.80622	15.44558	0101000020110F0000845DC119623C3A41B756E159F98B5641	JN76RT	Estimate Google Maps, Mitteregg	419.7	550	\N	Leibnitz	Mitteregg	OE6SSF	\N	\N	\N	\N	\N	active	t	\N	\N	103.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	126	MITTEREGG	dumb2	OE6
2145	repeater_voice	438.75	431.15	12.5	V	OE6XGD	47.0938	15.69455	0101000020110F000065597150A5A83A4192DA3F85C5B95641	JN77UB	Google Maps Ungerdorf 25	406.3	480	\N	Gleisdorf	Ungerdorf Ort	OE6ERD	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	127	GLEISDORF	dumb2	OE6
2149	repeater_voice	438.8	431.2	12.5	V	OE6XMD	47.063469	14.567296	0101000020110F00005E9213F977BE3841F5E949FFEDB45641	JN77GB	https://www.peakbagger.com/peak.aspx?pid=10154	2394.2	2376	\N	Murtal	Zirbitzkogel	OE6WVG	\N	\N	\N	t	\N	active	t	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	131	MURTAL ZIRBITZKOGEL	dumb2	OE6
2151	repeater_voice	439	431.4	12.5	V	OE6XNG	47.11856	14.93233	0101000020110F0000FF94385F335D3941C34854E6B9BD5641	JN77KD	Google Maps, Wiedernalm	1595.6	1600	\N	Zeltweg	Gaberl/Wiedneralm	OE6NPG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	133	GABERL WIEDNERALM	dumb2	OE6
2152	repeater_voice	439.05	431.45	12.5	V	OE6XPF	46.91079	15.2744	0101000020110F00009DCD1F6EF2F139416B117B37999C5641	JN76PV	Rougth estimate, Google Maps Pichling	355	390	\N	Stainz	Pichling	OE6MRG	\N	\N	\N	\N	\N	active	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	134	PICHLING BEI STAINZ	dumb2	OE6
2146	repeater_voice	51.93	51.33	12.5	V	OE6XIE	47.08036	14.95033	0101000020110F0000DE416F1F076539415D59E12FA0B75641	JN77LC	Estimate Google Maps Stubalpe	1326.8	1500	\N	Köflach	Stubalpe	OE6PZG	\N	\N	\N	\N	\N	active	t	Tone 1750	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	128	STUBALPE	dumb2	OE6
2162	repeater_voice	438.825	431.225	12.5	V	OE7XFJ	47.48446	12.42795	0101000020110F0000E970CB10311C354190DF90FA61F85641	JN67FL	https://hamnetdb.net/?m=site&q=oe7xfj&as=-All-&tab=	1601.1	1600	\N	St. Johann in Tirol	Harschbichl	OE7GBJ	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	144	ST.JOHANN/TIROL HARSCHBICHL	dumb2	OE7
2173	repeater_voice	438.875	431.275	12.5	V	OE7XLI	46.82166	12.70025	0101000020110F0000CB1CEA5C9992354104CCDB376D8E5641	JN66IT	Approx Gmaps	2018.9	2023	\N	Lienz	Hochstein	OE7JTK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	155	LIENZ HOCHSTEIN	dumb2	OE7
2182	repeater_voice	438.35	430.75	12.5	V	OE7XTT	47.168667	11.8	0101000020110F000065CFC9FD210B34413607021ABCC55641	JN57VE	https://hamnetdb.net/?m=site&q=oe7xtt&as=-All-&tab=	2085.6	2095	\N	Zillertal	Penkenjoch	OE7FMI	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	164	ZILLERTAL PENKENJOCH	dumb2	OE7
2201	repeater_voice	438.6	431	12.5	V	OE8XKK	46.608914	14.14479	0101000020110F0000E92BF7D1BE0638414B59AEB8B16C5641	JN76BO	https://www.peakbagger.com/peak.aspx?pid=47628	848.6	934	\N	KLagenfurt	Pyramidenkogel	OE8HJK	\N	\N	\N	\N	\N	active	\N	\N	\N	\N	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2021-10-16 14:40:51.350258+02	183	PYRAMIDENKOGEL	dumb2	OE8
\.


--
-- Name: repeater_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.repeater_uid_seq', 2298, true);


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
-- Name: repeater repeater_trigger; Type: TRIGGER; Schema: public; Owner: dz
--

CREATE TRIGGER repeater_trigger BEFORE INSERT OR UPDATE ON public.repeater FOR EACH ROW EXECUTE FUNCTION public.trigger_repeater();


--
-- PostgreSQL database dump complete
--

