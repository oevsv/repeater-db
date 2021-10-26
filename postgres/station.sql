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
-- Name: station; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.station (
    uid bigint NOT NULL,
    name character varying(100) NOT NULL,
    city character varying(100),
    longitude double precision,
    latitude double precision,
    see_level double precision,
    locator_short character varying(6),
    locator_long character varying(20),
    geo_prefix character varying(3),
    bev_gid integer,
    geom public.geometry(Geometry,3857),
    dummy character varying
);


ALTER TABLE public.station OWNER TO dz;

--
-- Name: COLUMN station.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.uid IS 'UID';


--
-- Name: COLUMN station.name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.name IS 'Name of station, e.g. Grünberg';


--
-- Name: COLUMN station.city; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.city IS 'Bigger city around station (to identify station)';


--
-- Name: COLUMN station.longitude; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.longitude IS 'Longitude of station, e.g. 48. North is positive';


--
-- Name: COLUMN station.latitude; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.latitude IS 'Latitude of station, e.g. 15. East is positive';


--
-- Name: COLUMN station.see_level; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.see_level IS 'See level using WGS84 geoid in meter.';


--
-- Name: COLUMN station.locator_short; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.locator_short IS 'Short locator, e.g. JN78ab';


--
-- Name: COLUMN station.locator_long; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.locator_long IS 'Long locator (exact location)';


--
-- Name: COLUMN station.geo_prefix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.geo_prefix IS 'Amateur radio prefix of Austrian location, e.g. OE3';


--
-- Name: COLUMN station.bev_gid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.bev_gid IS 'GID of BEV table (pointer to community, etc.)';


--
-- Name: COLUMN station.geom; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.station.geom IS 'Geometry of location';


--
-- Name: station_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.station_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.station_uid_seq OWNER TO dz;

--
-- Name: station_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.station_uid_seq OWNED BY public.station.uid;


--
-- Name: station uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.station ALTER COLUMN uid SET DEFAULT nextval('public.station_uid_seq'::regclass);


--
-- Data for Name: station; Type: TABLE DATA; Schema: public; Owner: dz
--

COPY public.station (uid, name, city, longitude, latitude, see_level, locator_short, locator_long, geo_prefix, bev_gid, geom, dummy) FROM stdin;
74	Linz Froschberg	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
100	Schellenberg	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
1	Ahorn	Mayhofen	11.86928	47.13717	1952	JN57WD	JN57WD42HW50GX38IB69	OE7	6024	0101000020110F000087A0A73442293441CE603A21B3C05641	a
2	Arsenal Funkturm	Wien	16.3908	48.18185	198	JN88EE	JN88EE63VP54AN94OJ45	OE1	7841	0101000020110F0000D9547B8267D73B410A83566C52695741	a
3	Axams / Hoadl	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
4	Bazora	Feldkirch	\N	\N	\N	\N	\N	\N	\N	\N	a
5	Bisamberg	Wien	16.3827774	48.3106475	306	JN88EH	JN88EH54WN33XH71JA39	OE1	7152	0101000020110F0000A5541D70EAD33B41F64872FF587E5741	a
6	Braunau Ort	Braunau am Inn	13.0286	48.24392	356	JN68MF	JN68MF38KM39QT30EB89	OE5	6281	0101000020110F000081D0241E61213641B5049CB272735741	a
7	Breitenstein	Linz	14.27429015	48.4152993	955	JN78DJ	JN78DJ29VQ91NF37MM45	OE5	701	0101000020110F0000E5BBFFB50E3F3841CE991283788F5741	a
8	Brentenriegel	Mattersburg	16.390592	47.659535	605	JN87EP	JN87EP68UG99BF11VU61	OE4	1257	0101000020110F00004E07F15A50D73B41C71D01D697145741	a
9	Bruckerberg	Bruck am Ziller	11.874329	47.381759	1050	JN57WJ	JN57WJ41WO09QH26BJ19	OE7	978	0101000020110F0000BCA4FE41742B34413AF762C0E0E75641	a
10	Buschberg	Mistelbach	16.39555	48.577044	490	JN88EN	JN88EN78LL17UR16OG41	OE3	1097	0101000020110F00009589FB4678D93B413F693B3E01AA5741	a
11	Damberg	Steyr	14.45225	48.0072	658	JN78FA	JN78FA41GR44TR12XT92	OE5	3137	0101000020110F000038825E1C718C38412AE07B2FE54C5741	a
12	Dobl	Graz	15.37989	46.94991	349	JN76QW	JN76QW57OX04TT95QU31	OE6	3690	0101000020110F00005624F485D11F3A4175C6117CD3A25641	a
13	Dobratsch	Villach	13.670989	46.603397	2159	JN66UO	JN66UO04MT45LQ50XD20	OE8	6267	0101000020110F0000101EBC88B73837412A541C3CD26B5641	a
14	Donauturm	Wien	16.4099	48.24052	165	JN88EF	JN88EF97ER53CW88TL15	OE1	7709	0101000020110F0000FA9143B6B5DF3B415550A09EE4725741	a
15	Dornbirn Stadt	Dornbirn	9.72684	47.39798	429	JN47UJ	JN47UJ75FM23XP85BM94	OE9	923	0101000020110F0000943D36E0A2853041EF35738D7BEA5641	a
16	Dünserberg	Bludenz	9.737786	47.22903	1333	JN47UF	JN47UF84MX82FD60TR92	OE9	1060	0101000020110F0000726E0461658A30411FA0518364CF5641	a
17	Eisenerzer Reichenstein	Leoben	14.93429	47.505327	1850	JN77LM	JN77LM21CG76NU20LK57	OE6	2270	0101000020110F00006883E38E0D5E39410450747ABDFB5641	a
18	Eisvogelgasse	Wien	16.3404457	48.1899867	182	JN88EE	JN88EE05UO43UF06QD23	OE1	1550	0101000020110F0000C8943B1882C13B4110352F10A66A5741	a
19	Exelberg	Wien	16.2440474	48.24876033	515	JN88CF	JN88CF99GQ88NO52PT02	OE3	1683	0101000020110F000039E4C11597973B41C415E6FA3C745741	a
20	Feldkirch	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
21	Finkenstein/Neumüllern	Villach	13.83948	46.56579	507	JN66WN	JN66WN05RS79AM50SX20	OE8	7550	0101000020110F00000041CFDDFB813741522AEA6DDF655641	a
22	Frankenmarkt	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
23	Frastanz	Feldkirch	\N	\N	\N	\N	\N	\N	\N	\N	a
24	Frauenstaffel	Waidhofen an der Thaya	15.3499052	48.7931928	679	JN78QT	JN78QT10XI77GV47RG84	OE3	6633	0101000020110F00003C486EA1C7123A41BEB756C798CD5741	a
25	Fronberg	Kirchberg an der Pielach	15.43243	48.03663	516	JN78RA	JN78RA18VS39XV63DC88	OE3	7822	0101000020110F0000944FD23FAA363A4149194DBBAD515741	a
26	Gaberl/Wiedneralm	Zeltweg	14.93233	47.11856	1596	JN77LC	JN77LC18VK19CB43XK05	OE6	6571	0101000020110F0000FF94385F335D3941C34854E6B9BD5641	a
27	Gaisberg	Salzburg	13.112955	47.805128	1281	JN67NT	JN67NT33NF35CI49XL03	OE2	6139	0101000020110F0000066C30790F4636411387E905202C5741	a
28	Gallzein Kogelmoos	Jenbach	11.755	47.357	1108	JN57VI	JN57VI05OQ33XE97XX99	OE7	6287	0101000020110F0000331F419D90F733411EE43E5FE7E35641	a
116	St. Johann am Walde	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
29	Gebhartsberg	Bregenz	9.74761	47.49003	596	JN47UL	JN47UL97RO15ER04HR62	OE9	5688	0101000020110F0000EF814DFBAA8E3041CD4FD35E47F95641	a
30	Gefrorene Wand	Hintertux	11.679196	47.064977	3247	JN57UB	JN57UB15MO02UQ22SB01	OE7	6	0101000020110F000055EBCE269AD63341CCD3789B2BB55641	a
31	Geiersberg	Ried	13.58142	48.20026	565	JN68SE	JN68SE98SB44VX54AF97	OE5	1437	0101000020110F0000E5DB36C2C4113741232B37F7526C5741	a
32	Gerlitzen	Villach	13.914167	46.695	1909	JN66WQ	JN66WQ96QT81AX29HX29	OE8	501	0101000020110F0000338339FC75A2374154537DE8537A5641	a
33	Gernkogel	St. Johann im Pongau	13.238225	47.30755	1785	JN67OH	JN67OH83OT04VV11EE77	OE2	30	0101000020110F000079384C77887C36415ABBD2D5F8DB5641	a
34	Gießhübel	Mödling	16.23893	48.09671	398	JN88CC	JN88CC83QF10EL49DA89	OE3	1941	0101000020110F0000E72D2B6B5D953B41DFC18DC2735B5741	a
35	Goldeck	Spittal an der Drau	13.45725	46.76179	2049	JN66RS	JN66RS42UT89TC14XX90	OE8	6740	0101000020110F0000B49FAC37C6DB3641FB0E819CEB845641	a
36	Grambach Ort	Graz	15.4962	47.00617	337	JN77RA	JN77RA91NL05NJ44JB69	OE6	4356	0101000020110F000006F8DD1765523A4155FFD24ECAAB5641	a
37	Grünberg	Gmunden	13.8219805	47.8981318	977	JN67VV	JN67VV85PN32AJ94FA10	OE5	6573	0101000020110F0000B85EBDD45F7A3741BA690513313B5741	a
38	Grünberg bei Silz	Silz	10.91478	47.28231	1491	JN57KG	JN57KG97SS51PB93IK65	OE7	3628	0101000020110F0000FDC270C0338A324159D1E426EDD75641	a
39	Hadersdorf	Wien	16.2259	48.21688	255	JN88CF	JN88CF72CB52WG09TC18	OE1	1700	0101000020110F00000139F8ECB28F3B4193522D05096F5741	a
40	Hahnenkamm	Reutte	10.641632	47.478174	1906	JN57HL	JN57HL64XS92AT07JJ20	OE7	3421	0101000020110F0000A6EE310E6D133241006707215FF75641	a
41	Hainfelder Hütte	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
42	Harschbichl	St. Johann in Tirol	12.42795	47.48446	1601	JN67FL	JN67FL16IG44XV05JA69	OE7	5730	0101000020110F0000E970CB10311C354190DF90FA61F85641	a
43	Haunsberg	Salzburg	12.996526	47.914961	832	JN67LV	JN67LV99NO91WS70RU07	OE2	7803	0101000020110F00006EEE09A86E1336415D1220C1EB3D5741	a
44	Hermannskogel	Wien	16.29324	48.270327	541	JN88DG	JN88DG54EV50HU40VK17	OE1	6419	0101000020110F000093CA1F2EFBAC3B41ABBF9781C2775741	a
45	Hinteralm Traisnerhütte	Lilienfeld	15.61039	47.97206	1314	JN77TX	JN77TX33FH90FP57QK35	OE3	5837	0101000020110F0000946677AA0C843A41C1E9D6F72F475741	a
46	Hoadl	Innsbruck	11.281548	47.183272	2336	JN57PE	JN57PE33SX86NL92SD60	OE7	3584	0101000020110F0000EE95C02DB0293341D0A4FA0C12C85641	a
47	Hochkar	Waidhofen an der Ybbs	14.901111	47.710833	1807	JN77KR	JN77KR80DO13XX95FJ54	OE3	1126	0101000020110F00005EE5B916A04F394149A8A077E01C5741	a
48	Hochkogelberg	Randegg	14.951167	48.034278	712	JN78LA	JN78LA48DF34OJ69HB27	OE3	1758	0101000020110F0000C4A3154C64653941282B94D74B515741	a
49	Hochköngi Matrashaus	Bischofshofen	13.062393	47.420263	2939	JN67MK	JN67MK70LU67WD05JR90	OE2	5414	0101000020110F0000C1FFF2EF12303641D61670E10FEE5641	a
50	Hochstein	Lienz	12.70025	46.82166	2019	JN66IT	JN66IT47AE77EO87AU01	OE7	233	0101000020110F0000CB1CEA5C9992354104CCDB376D8E5641	a
51	Hochwechsel	Mürzzuschlag	15.9145156	47.530448	1740	JN77WM	JN77WM97RH83BT13TD86	OE3	3968	0101000020110F0000D61CD7C54B083B4169FBABA6C8FF5641	a
52	Hoher Sonnblick	Heiligenblut	12.957194	47.05397	3100	JN67LB	JN67LB42UW78EQ41WG27	OE2	7312	0101000020110F00005DFFF93C54023641C37B6EF369B35641	a
53	Hohe Salve	Kufstein	12.204167	47.465	1828	JN67CL	JN67CL41MO04AA20HA20	OE7	4802	0101000020110F0000D15BEFA7E1BA3441D28186BD40F55641	a
54	Hohe Wand	Wr. Neustadt	16.04605	47.8346	918	JN87AU	JN87AU50MH62FX70OJ45	OE3	7574	0101000020110F00008A97801D7E413B41F57A6289E5305741	a
55	Hornstein/Sonnenberg	Eisenstadt	16.470265	47.875253	439	JN87FV	JN87FV60KB34PN17QL33	OE4	7367	0101000020110F0000C1F35583F5F93B415C057F9A7B375741	a
56	Hunerkogel	Dachstein	13.627424	47.467376	2590	JN67TL	JN67TL52GE90TU45QT57	OE5	7284	0101000020110F0000B56E87E6C5253741D4C58C8DA2F55641	a
57	Hutwisch	Schäffern	16.22183	47.463146	895	JN87CL	JN87CL61OD87QF80XH02	OE3	470	0101000020110F0000DE3CF7DAED8D3B41AD2B816BF4F45641	a
58	Iselsberg-Stronach	Lienz	12.84436	46.83869	1130	JN66KU	JN66KU11HG78NN60HN64	OE7	5192	0101000020110F00007045619D43D13541555AA6F321915641	a
59	Jauerling	Spitz an der Donau	15.337681174278261	48.334521482895106	959	JN78QI	JN78QI00MG58FK24GX65	OE3	1847	0101000020110F00001B99B7DB760D3A41CA4BE83440825741	a
60	Jochgrabenberg	Pressbaum	16.03118	48.15183	573	JN88AD	JN88AD36RK75XJ67DW80	OE3	2021	0101000020110F000045CD5ECB063B3B41510E62CD6D645741	a
61	Kahlenberg	Wien	16.333217	48.276145	483	JN88DG	JN88DG96XG65PW58VL65	OE1	1888	0101000020110F000043C042665DBE3B4119B53EC6B5785741	a
62	Kaiserkogel	St. Pölten	15.53965351	48.05978708	712	JN78SB	JN78SB44SI23AR56BO42	OE3	4689	0101000020110F00005BB3DA504A653A419723D8C271555741	a
63	Kaltenbach	Zillertal	11.87464	47.29529	553	JN57WH	JN57WH40WU98PQ18QX30	OE7	1117	0101000020110F0000E9A9CEE0962B3441E11831B401DA5641	a
64	Kindberg Ort	Bruck an der Mur	15.44903	47.50585	568	JN77RM	JN77RM31VJ26BX50IJ66	OE6	6478	0101000020110F0000962D2127E23D3A4140AF5806D3FB5641	a
65	Kitzsteinhorn	Zell am See	12.687513	47.188104	3197	JN67IE	JN67IE25MD04IS99UQ57	OE2	215	0101000020110F0000845C917C0F8D35416D446EEAD7C85641	a
66	Kleinhardersdorf Ort	Kleinhadersdorf	16.59337	48.66351	213	JN88HP	JN88HP19EF98BE32KF57	OE3	7528	0101000020110F0000ABD1BA7F7D2F3C4169E2837039B85741	a
67	Klippitztörl	Wolfsberg	14.67506	46.93639	1626	JN76IW	JN76IW14AR16RB45RI26	OE8	5643	0101000020110F00001C2AE13454ED384108F3655EACA05641	a
68	Klosterneuburgerhütte	Judenburg	14.34483	47.25505	1765	JN77EG	JN77EG11JF10CV41XE07	OE6	6172	0101000020110F00005843CE2BBB5D3841C2CCCF228FD35641	a
69	Krahberg	Landeck	10.626826	47.145919	2203	JN57HD	JN57HD55FA24OW14HG41	OE7	5188	0101000020110F00007AEDEBDBFC0C3241D487151819C25641	a
70	Krippenstein	Obertraun	13.69208	47.524287	2106	JN67UM	JN67UM35BT18VW63XL07	OE5	7284	0101000020110F000004BF9D5FE3413741C7D0DAB9CAFE5641	a
71	Laaerberg	Wien	16.396717	48.157173	252	JN88ED	JN88ED77OR53KD79VN62	OE1	4375	0101000020110F00005A30E72FFAD93B41DC6D1AB14C655741	a
72	Laaerberg Schule	Wien	16.39578	48.15508	250	JN88ED	JN88ED77LF82LO15IW60	OE1	4375	0101000020110F0000406479E191D93B41C3BD8860F5645741	a
73	Lichtenberg	Linz	14.25445	48.38515	927	JN78DJ	JN78DJ02MK84DP83JO54	OE5	7346	0101000020110F0000FAE8931D6E363841F51A11BC888A5741	a
75	Magdalensberg	Klagenfurt	14.429426	46.728051	1059	JN76FR	JN76FR14MR75LR27MA25	OE8	6744	0101000020110F00001A80D15A84823841A1B69F5F917F5641	a
76	Mitteregg	Leibnitz	15.44558	46.80622	420	JN76RT	JN76RT33LL28QG85XG07	OE6	5948	0101000020110F0000845DC119623C3A41B756E159F98B5641	a
77	Mönichkirchen Ort	Mönichkirchen	16.037665	47.510703	948	JN87AM	JN87AM42MN46SL08LG55	OE3	5507	0101000020110F0000764189B3D83D3B41843CCEF79AFC5641	a
78	Nebelstein	Weitra	14.77828	48.672816	1005	JN78JQ	JN78JQ31JL44LE18IJ62	OE3	1241	0101000020110F000062FCB99A361A394181287D97C1B95741	a
79	Oberaich	Bruck an der Mur	15.19713	47.43786	762	JN77OK	JN77OK35PC70IR26NP43	OE6	4358	0101000020110F00008023EBC558D03941801CA2C8E3F05641	a
80	Ort-OE5SIX	Stadt-OE5SIX	\N	\N	\N	\N	\N	\N	\N	\N	a
81	Ottakring	Wien	16.32542	48.21328	207	JN88DF	JN88DF91BE24CW32AR92	OE1	1367	0101000020110F0000B5B1FE70F9BA3B41C55515AA726E5741	a
82	Patscherkofel	Innsbruck	11.460929	47.208287	2243	JN57RE	JN57RE59HX47SH19FL97	OE7	7526	0101000020110F0000C799C1C7B0773341F5C4009512CC5641	a
83	Penkenjoch	Zillertal	11.8	47.168667	2086	JN57VE	JN57VE50XL95XF92XO95	OE7	6	0101000020110F000065CFC9FD210B34413607021ABCC55641	a
84	Penzing/Breitenseerstraße	Wien	16.29932	48.20296	249	JN88DE	JN88DE58WR00JL99UA19	OE1	3085	0101000020110F00003C6AAF00A0AF3B4126A3F1B3C36C5741	a
85	Petzen	Bleiburg/Pliberk	14.772985	46.518507	1678	JN76JM	JN76JM24SK16XA20HS64	OE8	5584	0101000020110F00003B2BEE2AE9173941AFBB9250665E5641	a
86	Pfänder	Bregenz	9.7792	47.50601	1023	JN47VM	JN47VM31MK06XE02JF67	OE9	502	0101000020110F000040437A90679C3041B4D1D19DD9FB5641	a
87	Pfarrkirchen Ort	Pfarrkirchen im Mühlkreis	13.825623	48.502872	813	JN68VM	JN68VM90BQ75WK62EM26	OE5	780	0101000020110F0000A241F04FF57B3741CB313794D39D5741	a
88	Pichling	Stainz	15.2744	46.91079	355	JN76PV	JN76PV28WO21RM20TX20	OE6	5283	0101000020110F00009DCD1F6EF2F139416B117B37999C5641	a
89	Plabutsch	Graz	15.385301	47.090608	753	JN77QC	JN77QC61FR69QA04MX28	OE6	6558	0101000020110F0000F6517EDF2B223A413CA98F0A43B95641	a
90	Planai	Schladming	13.726221	47.369088	1905	JN67UI	JN67UI78DN59DL92NM22	OE6	2083	0101000020110F0000B403A7EEBB50374100122506D8E55641	a
91	Pointen/Wasserbehälter	Frankenmark	13.4224	47.99241	567	JN67RX	JN67RX08QE52CT85TU21	OE5	2768	0101000020110F00004E8BB4BB9ECC3641268E380E7E4A5741	a
92	Pyramidenkogel	KLagenfurt	14.14479	46.608914	849	JN76BO	JN76BO76ID93WK87LD52	OE8	1747	0101000020110F0000E92BF7D1BE0638414B59AEB8B16C5641	a
93	Rangger Köpl	Oberpferfuss	11.181174	47.242985	1938	JN57OF	JN57OF18RH75TW44QP53	OE7	7368	0101000020110F0000ED599D980AFE32413142477FA0D15641	a
94	Rennfeld	Bruck an der Mur	15.35936	47.40554	1618	JN77QJ	JN77QJ37CH99NC64HX60	OE6	4454	0101000020110F000013125522E4163A41E620C564B2EB5641	a
95	Rittmannsberg 	St. Valentin	14.5319725	48.1746467	267	JN78GE	JN78GE31UV09TP35WX05	OE3	5660	0101000020110F0000346C67C71BAF3841BCBA36CA25685741	a
96	Rofan Roßkogel	Kramsach	11.82695	47.46738	1921	JN57VL	JN57VL92FE61DC81JC58	OE7	890	0101000020110F00009B1D380DDA1634416CADB4B7A2F55641	a
97	Rossegger Str/LWZ	Klagenfurt	14.29801	46.61189	441	JN76DO	JN76DO56SU24QU57CI86	OE8	5333	0101000020110F00009F6C4B315F493841A749E9482A6D5641	a
98	Sandl	Krems	15.471389	48.43338	697	JN78RK	JN78RK64NA62AQ05SC48	OE3	7700	0101000020110F0000A84E35259B473A41640105C46E925741	a
99	Satzberg	Wien	16.261484	48.215096	432	JN88DF	JN88DF11JO09RM77JC74	OE1	2027	0101000020110F0000ACF7501E2C9F3B41340B5D82BE6E5741	a
101	Schöckl	Graz	15.465789	47.198505	1444	JN77RE	JN77RE57VP43RV33NC68	OE6	7814	0101000020110F00002D1396C12B453A415F2BE4E281CA5641	a
102	Schönjöchl	\N	10.59878	47.07803	2489	JN57HB	JN57HB18UR44UM76IR62	OE7	2084	0101000020110F000094CBE9CACA00324150C08BF740B75641	a
103	Sechszeiger	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
104	Seegrube	Innsbruck	11.377861	47.305572	1913	JN57QH	JN57QH53II20JW57FH58	OE7	3859	0101000020110F000011BE5DB1915333419ED53EA7A7DB5641	a
105	Senftenbach/Wolfau	Ried im Innkreis	13.40661	48.27889	476	JN68QG	JN68QG86TW04IB85HI66	OE5	5214	0101000020110F00005B569BFFC0C53641AE2B8E8F28795741	a
106	Sonnenberg	Amstetten	14.764472	47.996538	713	JN77JX	JN77JX19RE60TO01LH14	OE3	5979	0101000020110F0000F8423F81351439412323A6B9294B5741	a
107	Speiereck	Lungau	13.624763	47.127031	2388	JN67TD	JN67TD40XL36EX16UN50	OE2	1385	0101000020110F0000B729E9AD9D24374107B0145E14BF5641	a
108	Stadt/AKH	Wien	16.34684	48.22075	198	JN88EF	JN88EF12OX85XE88BA90	OE1	4745	0101000020110F00006228A6E749C43B417C1A1FAAAA6F5741	a
109	Stadt/Brixner Straße	Innsbruck	11.39865	47.264819	580	JN57QG	JN57QG73UN13CN87TU25	OE7	3227	0101000020110F00001F42EAE99B5C334191C2F1B91FD55641	a
110	Stadt/Froschberg	Linz	14.27855	48.28849	327	JN78DG	JN78DG39KF27FA75OS42	OE5	6840	0101000020110F000059E44EEAE840384145D8450CBA7A5741	a
111	Stadt/LKH	Villach	13.85777	46.61612	494	JN66WO	JN66WO27WU38SM62FV71	OE8	1598	0101000020110F000013D561E6EF893741B7C559A9D56D5641	a
112	Sternstein	Bad Leonfelden	14.2690062	48.5599155	1105	JN78DN	JN78DN24GJ71JD01UU59	OE5	5064	0101000020110F0000DD761A81C23C3841901775E030A75741	a
113	Steyr Stadt	Steyr	14.41718	48.05321	337	JN78FB	JN78FB02BS44SV85DA89	OE5	47	0101000020110F000092EAE222317D384165DCC2E95F545741	a
114	St. Georgen am Längsee Ort	St Veit an der Glan	14.43904	46.80088	620	JN76FT	JN76FT22QF40IQ45LC58	OE8	5339	0101000020110F0000C2679194B286384150F6FA3D208B5641	a
115	Stilluppklamm	Mayhofen	11.84865	47.15829	644	JN57WD	JN57WD17UX17CM80TX10	OE7	6024	0101000020110F0000102441AF49203441AA54455A13C45641	a
117	Stradner Kogel	Bad Gleichenberg	15.931635	46.845678	608	JN76XU	JN76XU12TX11CB12CQ81	OE6	7340	0101000020110F0000077AE67EBD0F3B41B07B95443E925641	a
118	Stubalpe	Köflach	14.95033	47.08036	1327	JN77LB	JN77LB49AG98MR06XP03	OE6	4016	0101000020110F0000DE416F1F076539415D59E12FA0B75641	a
119	Stuhleck	Mürzzuschlag	15.79	47.574167	1781	JN77VN	JN77VN47TT22AA04AO05	OE6	5350	0101000020110F0000F4D576C226D23A414D621C62D3065741	a
120	St. Ulrich am Pillersee Ort	Saalfelden	12.57709	47.52365	849	JN67GM	JN67GM95GQ02EF67BO94	OE7	2604	0101000020110F0000115E24410B5D3541A2D34A79B0FE5641	a
121	St. Wolfgang Ort	Deutschlandsberg	15.19524956997774	46.79450308163905	759	JN76OT	JN76OT30KQ33EJ50AO64	OE6	825	0101000020110F00007DBDD17187CF394145E7D4001D8A5641	a
122	Troppberg	Purkersdorf	16.110077	48.223986	540	JN88BF	JN88BF33FS01FO22FL31	OE3	4966	0101000020110F00007FD37A91555D3B41B88743D631705741	a
123	Ungerdorf Ort	Gleisdorf	15.69455	47.0938	406	JN77UC	JN77UC32IM32AV91OE47	OE6	1408	0101000020110F000065597150A5A83A4192DA3F85C5B95641	a
124	Unterberg	Pernitz	15.81881	47.93742	1320	JN77VW	JN77VW84GX15RJ44RB29	OE3	5919	0101000020110F000061A8C8DFADDE3A412729D88390415741	a
125	Valluga	Arlberg	10.21305436	47.15761255	2808	JN57CD	JN57CD57NT58XL15RV63	OE7	6807	0101000020110F0000E3BCC302105931415FBE53A0F7C35641	a
126	Vorderälpele	Feldkirch	9.591069	47.20918	1315	JN47TF	JN47TF00WE28SS84WH26	OE9	6436	0101000020110F00007A72D0EA984A3041DD5A502A37CC5641	a
127	Weinbergerhaus	Kufstein	12.20958	47.57772	1269	JN67CN	JN67CN58DP56VQ61XG07	OE7	5167	0101000020110F0000B967783A3CBD34417675A3F465075741	a
128	Weiterner Straße/HTL	St. Pölten	15.62219	48.22104	291	JN78TF	JN78TF43PB91BV76GX70	OE3	3695	0101000020110F0000C05A623C2E893A41AF2725C7B66F5741	a
129	Wieden/Gußhausstraße	Wien	16.370982687332315	48.19669506334071	172	JN88EE	JN88EE47ME49HP22IN03	OE1	7827	0101000020110F0000F6C2DF74C9CE3B41D2365F1FBE6B5741	a
130	Wienerberg	Wien	16.3454	48.16803	223	JN88EE	JN88EE10KH78MM46TR22	OE1	4176	0101000020110F0000D7FBD49AA9C33B418BE004AD11675741	a
131	Wölfnitz Ort	Klagenfurt	14.25703	46.66441	456	JN76DP	JN76DP09UL20LA13IU61	OE8	6132	0101000020110F00007703E0518D37384130E0840F7B755641	a
132	Wurmkogel Lift	Sölden	11.08384	46.88041	3020	JN56NV	JN56NV01BH41OO27BU91	OE7	4396	0101000020110F0000C0EDC16CB7D33241D76758EFC3975641	a
133	Zell am Pettenfirst	\N	\N	\N	\N	\N	\N	\N	\N	\N	a
134	Zirbitzkogel	Murtal	14.567296	47.063469	2394	JN77GB	JN77GB85BF85CT95WK89	OE6	3429	0101000020110F00005E9213F977BE3841F5E949FFEDB45641	a
135	Zugspitze Ö	Ehrwald	10.9843067	47.4211969	2936	JN57LK	JN57LK81CC80AW75VW86	OE7	2557	0101000020110F0000DE2EB66D6FA8324123B50E4B36EE5641	a
\.


--
-- Name: station_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: dz
--

SELECT pg_catalog.setval('public.station_uid_seq', 135, true);


--
-- Name: station station_trigger; Type: TRIGGER; Schema: public; Owner: dz
--

CREATE TRIGGER station_trigger BEFORE INSERT OR UPDATE ON public.station FOR EACH ROW EXECUTE FUNCTION public.trigger_station();


--
-- PostgreSQL database dump complete
--
