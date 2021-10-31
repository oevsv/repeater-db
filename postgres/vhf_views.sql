
--
-- Name: site_callsigns_all; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_all AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.status)::text = 'active'::text)
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_all OWNER TO dz;

--
-- Name: site_callsigns_beacon; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_beacon AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE (((trx.type_of_station)::text = 'beacon'::text) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_beacon OWNER TO dz;

--
-- Name: site_callsigns_c4fm; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_c4fm AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.c4fm = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_c4fm OWNER TO dz;

--
-- Name: site_callsigns_digipeater; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_digipeater AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE (((trx.type_of_station)::text = 'digipeater'::text) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_digipeater OWNER TO dz;

--
-- Name: site_callsigns_dmr; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_dmr AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.dmr = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_dmr OWNER TO dz;

--
-- Name: site_callsigns_dstar; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_dstar AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.dstar = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_dstar OWNER TO dz;

--
-- Name: site_callsigns_fm; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_fm AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.fm = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_fm OWNER TO dz;

--
-- Name: site_callsigns_tetra; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_tetra AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (trx.frequency_tx)::text, '/'::text ORDER BY (trx.frequency_tx)::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.tetra = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_tetra OWNER TO dz;
