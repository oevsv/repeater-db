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

--
-- Name: api; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA api;


ALTER SCHEMA api OWNER TO postgres;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_raster; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;


--
-- Name: EXTENSION postgis_raster; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_raster IS 'PostGIS raster types and functions';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: band_name(double precision); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.band_name(frequency double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;

	BEGIN
select band_name into name from bands where 
    frequency >= frequency_from and
    frequency <= frequency_to
    limit 1;
		
    return name;
	END;
$$;


ALTER FUNCTION public.band_name(frequency double precision) OWNER TO dz;

--
-- Name: channel_name(double precision); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.channel_name(frequency_tx double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      
   BEGIN
     -- default, use common (aka old) format - e.g. R1x
     RETURN  channel_name (frequency_tx,NULL,0);
   END
$$;


ALTER FUNCTION public.channel_name(frequency_tx double precision) OWNER TO dz;

--
-- Name: channel_name(double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.channel_name(frequency_tx double precision, frequency_rx double precision, format integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;

band6m_lower constant double precision := 50;

band6m_upper constant double precision := 54;     
     
band2m_lower constant double precision := 144;

band2m_upper constant double precision := 146;

band70cm_lower constant double precision := 430;

band70cm_upper constant double precision := 440;

band6m_offset constant double  precision := 0.6;

band2m_offset constant double  precision := 0.6;

band70cm_offset constant double  precision := 7.6; 

nonstandard_offset boolean := false;


chan2m_old varchar[] := '{"R00", "R00x", "R0", "R0x","R1","R1x","R2","R2x","R3","R3x",
							 "R4", "R4x","R5","R5x","R6","R6x","R7","R7x"}';
-- index for channel calculations
      idx integer;
      
      
   begin
	 -- check offset 
	 -- 6m band  
     if (frequency_tx >= band6m_lower and
         frequency_tx <= band6m_upper and 
       abs(frequency_tx - frequency_rx - band6m_offset) > 0.001) then  
          nonstandard_offset = true;
     end if;   
	 -- 2m band  
     if (frequency_tx >= band2m_lower and
         frequency_tx <= band2m_upper and 
       abs(frequency_tx - frequency_rx - band2m_offset) > 0.001) then  
          nonstandard_offset = true;
     end if;      
     -- 70cm band  
     if (frequency_tx >= band70cm_lower and
         frequency_tx <= band70cm_upper and 
       abs(frequency_tx - frequency_rx - band70cm_offset) > 0.001) then  
          nonstandard_offset = true;
     end if; 
     -- old format (R1, R70)
     if (format = 0) then
     
      -- 2m range R00 - R7x
      if (frequency_tx >= 145.575 and
          frequency_tx <= 145.7875) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          name = chan2m_old[round((frequency_tx-145.575)/0.0125)+1];
      end if;
      -- 70cm range R30-R123 (broad range, goes beyond real repepater channels)
      if (frequency_tx >= 437.650 and
          frequency_tx <= 439.975) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          -- idx is zero at 437.650 and progresses with 1/12,5kHz (would be R30)
          idx = round((frequency_tx-437.650)/0.0125);
          -- even number - thus no "x" added
          if (mod(idx,2)=0) then
            name = concat('R',(idx/2+30)::varchar);
          else 
            name = concat('R',(idx/2+30)::varchar,'x');
          end if;
       
      end if;
     else
     -- new format RV48, RU680
        -- 6m
        if (frequency_tx >= 51 and
          frequency_tx <= 54) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.01) - round(frequency_tx/0.01) < 0.001 then
          idx = round((frequency_tx-51)*100);
          name = concat('RF',(idx)::varchar);
        end if;
        -- 2m
        if (frequency_tx >= 145.2 and
          frequency_tx <= 145.7875) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          idx = round((frequency_tx-145)*80);
          name = concat('RV',(idx)::varchar);
        end if;
        -- 70cm
        if (frequency_tx >= 437.650 and
          frequency_tx <= 439.975) and 
          -- only exact match but ignore rounding errors
          (frequency_tx/0.0125) - round(frequency_tx/0.0125) < 0.001 then
          idx = round((frequency_tx-430)*80);
          name = concat('RU',(idx)::varchar);
        end if;
     end if;
      
     if (name is not null and nonstandard_offset) then
       name = concat (name,'!');
     end if;
     RETURN name;
   END
$$;


ALTER FUNCTION public.channel_name(frequency_tx double precision, frequency_rx double precision, format integer) OWNER TO dz;

--
-- Name: maidenhead_loc(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.maidenhead_loc(longitude double precision, latitude double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      
   BEGIN
     -- short default locator (3 pairs aka 6 digits
     RETURN  maidenhead_loc (longitude,latitude,3);
   END
$$;


ALTER FUNCTION public.maidenhead_loc(longitude double precision, latitude double precision) OWNER TO postgres;

--
-- Name: maidenhead_loc(double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.maidenhead_loc(longitude double precision, latitude double precision, pairs integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   DECLARE
      loc varchar;
      alphabet_c constant varchar := 'ABCDEFGHIJKLMNOPQRSTUVWX';
      alphabet_n constant varchar := '0123456789';
      lat_offset constant float8 := 90;
      lat_range constant float8 := 180;
      lat_rem float8;
      long_offset constant float8 := 180;
      long_range constant float8 := 360;
      long_rem float8;
      digit_n int;
      base int;
      c varchar;
      -- minimum number of pairs (e.g. JN68UB)      
      pairs_min constant int := 3;
      -- maximum pair number (goes beyond IARUs recommendation)
      pairs_max constant int := 10;
      counter int;
      
   BEGIN
      --  Lat 48.07823  Long 13.730722 Locator: JN68UB78QS  => J6I7Q und N8B8S
      -- range check parameters
      if (latitude > 90 or latitude < -90 or
          longitude > 180 or longitude < -180 or
          pairs < pairs_min or pairs > pairs_max) then 
        return NULL;        
      end if;

      loc = '';
      lat_rem = (latitude + lat_offset)/lat_range;
      long_rem = (longitude + long_offset)/long_range;
      -- long 180 and -180 are the same place, thus should have the same locator
      if long_rem = 1 then
        long_rem = 0;
      end if;  
      
      for counter in 1..pairs loop
         -- raise notice 'counter: %', counter;
                         
         -- determine base 
         if (counter = 1) then
            -- first pair is A-R
            -- 18 zones of longitude of 20° each
            -- 18 zones of latitude 10° each
            base = 18;
         else
           if (mod(counter,2)=1) then
             -- odd pair is A-X 
             base = 24;
           else
             -- even pair is 0-9
             base = 10;             
           end if;    
         end if;   
         -- raise notice 'base: %', base;
         -- longitude first in pair
          digit_n = trunc(long_rem*base);
          if (digit_n > base) then
            digit_n = base;
          end if;
          long_rem = (long_rem*base - digit_n);
          if (mod(counter,2)=1) then
            c = substr(alphabet_c,digit_n+1,1);
          else
            c = substr(alphabet_n,digit_n+1,1);
          end if;
          loc = concat (loc,c);
          -- raise notice 'Longitude: % % ', digit_n,lat_rem;
          -- latitude second in pair
          digit_n = trunc(lat_rem*base);
          if (digit_n > base) then
            digit_n = base;
          end if;
          lat_rem = (lat_rem*base - digit_n);
          if (mod(counter,2)=1) then
            c = substr(alphabet_c,digit_n+1,1);
          else
            c = substr(alphabet_n,digit_n+1,1);
          end if;
          loc = concat (loc,c);
          -- raise notice 'Latitude: % % ', digit_n,lat_rem;
      end loop;            
     RETURN loc;
   END
$$;


ALTER FUNCTION public.maidenhead_loc(longitude double precision, latitude double precision, pairs integer) OWNER TO postgres;

--
-- Name: nice_display(character varying); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.nice_display(org character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
        
    begin
	  org = replace(org,'Ä','Ae');
	  org = replace(org,'ä','ae');
	  org = replace(org,'Ö','Oe');
	  org = replace(org,'ö','oe');
	  org = replace(org,'Ü','ue');
	  org = replace(org,'ü','ue');
	  org = replace(org,'ß','ss');
      return org;
	END;
$$;


ALTER FUNCTION public.nice_display(org character varying) OWNER TO dz;

--
-- Name: nice_frq(double precision); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.nice_frq(frequency double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;
      idx bigint;
          
    begin
       -- idx progresses with 1/0,5kHz steps
       idx = round((frequency)/0.0001);
       -- even number - thus no extra digit added
       if (mod(idx,10)=0) then
         name = trim(to_char(frequency,'999 999 990.999'));
       else 
         -- use narrow space unicode (u2009) for final digit 
         name = trim(to_char(frequency,concat('999 999 999.999',E'\u2009','9')));
       end if;

       return name;
	END;
$$;


ALTER FUNCTION public.nice_frq(frequency double precision) OWNER TO dz;

--
-- Name: nice_geo(double precision); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.nice_geo(geo double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;
      deg bigint;
      minutes float8;
          
    begin
	   deg = trunc(geo);
	   minutes = (geo-deg)*60;
	   name = concat(
	       to_char(deg,'900'),
	       '°',
	       to_char(minutes, '90.999'),
	       E'\'');
       return name;
	END;
$$;


ALTER FUNCTION public.nice_geo(geo double precision) OWNER TO dz;

--
-- Name: nice_geo_dms(double precision); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.nice_geo_dms(geo double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
   declare
      name varchar;
      deg bigint;
      minutes float8;
      seconds float8;
          
    begin
	    -- 47°06'15"N
	   deg = trunc(geo);
	   minutes = (geo-deg)*60;
	   seconds = (minutes-trunc(minutes))*60;
	   name = concat(
	       to_char(deg,'900'),
	       '°',
	       to_char(trunc(minutes), '90'),
	       E'\'',
	       to_char(round(seconds), '90'),
	       E'\"');
       return name;
	END;
$$;


ALTER FUNCTION public.nice_geo_dms(geo double precision) OWNER TO dz;

--
-- Name: trigger_import_hamnet_site(); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.trigger_import_hamnet_site() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
           if (NEW.latitude is null or new.longitude is null)
           then
              NEW.geom = null;
           end if;

       if (NEW.latitude is not null and NEW.longitude is not null)
       then
           -- set geometry geom
           new.geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326),3857);

           -- set see level
           SELECT INTO NEW.sea_level ST_Value(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)))
           FROM dhm WHERE st_intersects(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)));   
           NEW.see_level = round(NEW.see_level);
           
           -- set geo prefix according to region
           SELECT map.prefix,bev.gid
                INTO NEW.geo_prefix, new.bev_gid
                FROM oesterreich_bev_vgd_lam as bev
                LEFT JOIN bl_kz_prefix map on map.bl_kz=bev.bl_kz, import_hamnet_site as r
                WHERE ST_intersects(ST_Transform(NEW.geom, 31287), bev.geom)
                LIMIT 1;
           -- set locator
           NEW.locator_short = maidenhead_loc(NEW.longitude,new.latitude);     
           NEW.locator_long = maidenhead_loc(NEW.longitude,new.latitude,10);     
           
       end if;
        
       return new;

    END;
$$;


ALTER FUNCTION public.trigger_import_hamnet_site() OWNER TO dz;

--
-- Name: trigger_site(); Type: FUNCTION; Schema: public; Owner: dz
--

CREATE FUNCTION public.trigger_site() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
           if (NEW.latitude is null or new.longitude is null)
           then
              NEW.geom = null;
           end if;

       if (NEW.latitude is not null and NEW.longitude is not null)
       then
           -- set geometry geom
           new.geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326),3857);

           -- set sea level
           SELECT INTO NEW.sea_level ST_Value(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)))
           FROM dhm WHERE st_intersects(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)));   
           NEW.sea_level = round(NEW.sea_level);
           
           -- set geo prefix according to region
           SELECT map.prefix,bev.gid
                INTO NEW.geo_prefix, new.bev_gid
                FROM oesterreich_bev_vgd_lam as bev
                LEFT JOIN bl_kz_prefix map on map.bl_kz=bev.bl_kz, site as r
                WHERE ST_intersects(ST_Transform(NEW.geom, 31287), bev.geom)
                LIMIT 1;
           -- set locator
           NEW.locator_short = maidenhead_loc(NEW.longitude,new.latitude);     
           NEW.locator_long = maidenhead_loc(NEW.longitude,new.latitude,10);     
           
       end if;
        
       return new;

    END;
$$;


ALTER FUNCTION public.trigger_site() OWNER TO dz;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: setting_options; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.setting_options (
    uid integer NOT NULL,
    object character varying,
    filter jsonb
);


ALTER TABLE public.setting_options OWNER TO postgres;

--
-- Name: settings; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.settings AS
 SELECT setting_options.uid,
    setting_options.object,
    setting_options.filter
   FROM public.setting_options;


ALTER TABLE api.settings OWNER TO postgres;

--
-- Name: site; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.site (
    uid bigint NOT NULL,
    site_name character varying(100) NOT NULL,
    city character varying(100),
    longitude double precision,
    latitude double precision,
    sea_level double precision,
    locator_short character varying(6),
    locator_long character varying(20),
    geo_prefix character varying(3),
    bev_gid integer,
    geom public.geometry(Geometry,3857),
    internal character varying(1000)
);


ALTER TABLE public.site OWNER TO dz;

--
-- Name: COLUMN site.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.uid IS 'UID';


--
-- Name: COLUMN site.site_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.site_name IS 'Name of station, e.g. Grünberg';


--
-- Name: COLUMN site.city; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.city IS 'Bigger city around station (to identify station)';


--
-- Name: COLUMN site.longitude; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.longitude IS 'Longitude of station, e.g. 48. North is positive';


--
-- Name: COLUMN site.latitude; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.latitude IS 'Latitude of station, e.g. 15. East is positive';


--
-- Name: COLUMN site.sea_level; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.sea_level IS 'See level using WGS84 geoid in meter.';


--
-- Name: COLUMN site.locator_short; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.locator_short IS 'Short locator, e.g. JN78ab';


--
-- Name: COLUMN site.locator_long; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.locator_long IS 'Long locator (exact location)';


--
-- Name: COLUMN site.geo_prefix; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.geo_prefix IS 'Amateur radio prefix of Austrian location, e.g. OE3';


--
-- Name: COLUMN site.bev_gid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.bev_gid IS 'GID of BEV table (pointer to community, etc.)';


--
-- Name: COLUMN site.geom; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.geom IS 'Geometry of location';


--
-- Name: COLUMN site.internal; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.site.internal IS 'Internal comment';


--
-- Name: site; Type: VIEW; Schema: api; Owner: dz
--

CREATE VIEW api.site AS
 SELECT site.uid,
    site.site_name,
    site.city,
    site.longitude,
    site.latitude,
    public.nice_geo(site.longitude) AS longitude_formated,
    public.nice_geo(site.latitude) AS latitude_formated,
    site.sea_level,
    site.locator_short,
    site.locator_long,
    site.geo_prefix,
    site.bev_gid,
    site.geom,
    public.st_askml(site.geom) AS st_askml
   FROM public.site;


ALTER TABLE api.site OWNER TO dz;

--
-- Name: trx; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.trx (
    uid bigint NOT NULL,
    type_of_station character varying(50) DEFAULT 'repeater_voice'::character varying NOT NULL,
    frequency_tx double precision,
    frequency_rx double precision,
    callsign character varying(10),
    antenna_heigth double precision,
    site_name character varying(100),
    sysop character varying(10),
    url character varying(500),
    hardware character varying(100),
    mmdvm boolean,
    solar_power boolean,
    battery_power boolean,
    status character varying,
    fm boolean,
    fm_wakeup character varying(50),
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
    cc integer
);


ALTER TABLE public.trx OWNER TO dz;

--
-- Name: TABLE trx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON TABLE public.trx IS 'All OE repeater, including packet radio and beacons (and other stuff using spectrum in the relevant bands, eg. transponders)';


--
-- Name: COLUMN trx.frequency_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.frequency_tx IS 'in MHz';


--
-- Name: COLUMN trx.frequency_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.frequency_rx IS 'in MHz';


--
-- Name: COLUMN trx.callsign; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.callsign IS 'Callsign with all characters in upper case without SSID';


--
-- Name: COLUMN trx.antenna_heigth; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.antenna_heigth IS 'heigth about ground in m';


--
-- Name: COLUMN trx.site_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.site_name IS 'Name of location, should fully identify station without city';


--
-- Name: COLUMN trx.sysop; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.sysop IS 'Callsign of sysop/keeper of station; might not be legally responsible for station';


--
-- Name: COLUMN trx.url; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.url IS 'URL including https://-Prefix of station, should be deep link';


--
-- Name: COLUMN trx.hardware; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.hardware IS 'Hardware of station';


--
-- Name: COLUMN trx.mmdvm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.mmdvm IS 'True if station is based on MMDVM-concept';


--
-- Name: COLUMN trx.solar_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.solar_power IS 'True if solar powered station';


--
-- Name: COLUMN trx.battery_power; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.battery_power IS 'True if battery powered station';


--
-- Name: COLUMN trx.status; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.status IS 'Status of operation: planed, active, inactive';


--
-- Name: COLUMN trx.fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.fm IS 'Analogue FM station';


--
-- Name: COLUMN trx.fm_wakeup; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.fm_wakeup IS 'Tone or DTMF needed for activation of repeater, eg. "1750 Hz" or "DTMF 1"; Subtone is not relevant here';


--
-- Name: COLUMN trx.ctcss_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.ctcss_tx IS 'CTCSS tone send by transmitter in Hz; NULL if no tone ';


--
-- Name: COLUMN trx.ctcss_rx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.ctcss_rx IS 'CTCSS tone required by receiver in Hz; NULL if no tone needed';


--
-- Name: COLUMN trx.echolink; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.echolink IS 'True if connected to Echolink';


--
-- Name: COLUMN trx.echolink_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.echolink_id IS 'Numeric ID in Echolink system';


--
-- Name: COLUMN trx.digital_id; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.digital_id IS 'Digital (DMR) ID of station, eg. 23205 or private ID eg. 932832';


--
-- Name: COLUMN trx.dmr; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dmr IS 'True if station supports DMR mode';


--
-- Name: COLUMN trx.ipsc2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.ipsc2 IS 'True if station is connected to IPSC2';


--
-- Name: COLUMN trx.brandmeister; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.brandmeister IS 'True if stations is connected to Brandmeister';


--
-- Name: COLUMN trx.network_registered; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.network_registered IS 'True if station is registered on digital network (including FM stations)';


--
-- Name: COLUMN trx.c4fm; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.c4fm IS 'True if C4FM is supported';


--
-- Name: COLUMN trx.c4fm_groups; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.c4fm_groups IS 'Comma separated list of C4FM groups';


--
-- Name: COLUMN trx.dstar; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dstar IS 'True if Dstar is supported';


--
-- Name: COLUMN trx.dstar_rpt1; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dstar_rpt1 IS 'Dstar Repeater 1 - Upper case character, eg. A';


--
-- Name: COLUMN trx.dstar_rpt2; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.dstar_rpt2 IS 'Dstar Repeater 2 - Upper case character, eg. A';


--
-- Name: COLUMN trx.tetra; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.tetra IS 'True if Tetra station';


--
-- Name: COLUMN trx.other_mode; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.other_mode IS 'True if other mode (digital or analogue)';


--
-- Name: COLUMN trx.other_mode_name; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.other_mode_name IS 'Short description of the other mode (eg SSB USB)';


--
-- Name: COLUMN trx.comment; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.comment IS 'Public visible comment';


--
-- Name: COLUMN trx.internal; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.internal IS 'Internal comment (for administrative perposes)';


--
-- Name: COLUMN trx.created_at; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.created_at IS 'Timestamp of insert';


--
-- Name: COLUMN trx.cc; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.trx.cc IS 'Color Code (default DMR code is 1)';


--
-- Name: trx; Type: VIEW; Schema: api; Owner: dz
--

CREATE VIEW api.trx AS
 SELECT trx.uid,
    trx.type_of_station,
    COALESCE(public.band_name(trx.frequency_tx), public.band_name(trx.frequency_rx)) AS band,
    trx.frequency_tx,
    trx.frequency_rx,
    public.channel_name(trx.frequency_tx, trx.frequency_rx, 0) AS ch,
    public.channel_name(trx.frequency_tx, trx.frequency_rx, 1) AS ch_new,
    trx.callsign,
    trx.antenna_heigth,
    trx.site_name,
    trx.sysop,
    trx.url,
    trx.hardware,
    trx.mmdvm,
    trx.solar_power,
    trx.battery_power,
    trx.status,
    trx.fm,
    trx.fm_wakeup,
    trx.ctcss_tx,
    trx.ctcss_rx,
    trx.echolink,
    trx.echolink_id,
    trx.digital_id,
    trx.dmr,
    trx.cc,
    trx.ipsc2,
    trx.brandmeister,
    trx.c4fm,
    trx.c4fm_groups,
    trx.dstar,
    trx.dstar_rpt1,
    trx.dstar_rpt2,
    trx.tetra,
    trx.other_mode,
    trx.other_mode_name,
    trx.comment
   FROM public.trx;


ALTER TABLE api.trx OWNER TO dz;

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
-- Name: beacon_import; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.beacon_import (
    uid integer NOT NULL,
    frequency_tx double precision,
    callsign character varying,
    location_import character varying,
    locator_import character varying,
    sea_level_import integer,
    power character varying,
    sysop character varying,
    footnotes character varying,
    type_of_station character varying DEFAULT 'beacon'::character varying
);


ALTER TABLE public.beacon_import OWNER TO dz;

--
-- Name: COLUMN beacon_import.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.beacon_import.uid IS 'UID';


--
-- Name: beacon_import_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.beacon_import_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.beacon_import_uid_seq OWNER TO dz;

--
-- Name: beacon_import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.beacon_import_uid_seq OWNED BY public.beacon_import.uid;


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
-- Name: chirp_fm_raw; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.chirp_fm_raw AS
 SELECT concat("substring"((t.callsign)::text, 3, 4), '-', "substring"((public.band_name(t.frequency_tx))::text, 1, 1)) AS "Name",
    t.frequency_tx AS "Frequency",
    '-'::character varying AS "Duplex",
    (round(((t.frequency_tx - t.frequency_rx) * (10)::double precision)) / (10)::double precision) AS "Offset",
        CASE
            WHEN (t.ctcss_rx IS NOT NULL) THEN 'Tone'::text
            ELSE NULL::text
        END AS "Tone",
    COALESCE(t.ctcss_rx, t.ctcss_tx, (88.5)::double precision) AS "rToneFreq",
    COALESCE(t.ctcss_tx, t.ctcss_rx, (88.5)::double precision) AS "cToneFreq",
    '023'::character varying AS "DtcsCode",
    'NN'::character varying AS "DtcsPolarity",
    'FM'::character varying AS "Mode",
    '12.50'::character varying AS "TStep",
    ''::text AS "Skip",
    ''::text AS "Comment",
    ''::text AS "URCALL",
    ''::text AS "RPT1CALL",
    ''::text AS "RPT2CALL",
    ''::text AS "DVCODE"
   FROM public.trx t
  WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND (abs((t.frequency_tx - t.frequency_rx)) <= (7.7)::double precision))
  ORDER BY t.callsign, (public.band_name(t.frequency_tx));


ALTER TABLE public.chirp_fm_raw OWNER TO dz;

--
-- Name: chirp_fm; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.chirp_fm AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Location",
    cfr."Name",
    cfr."Frequency",
    cfr."Duplex",
    cfr."Offset",
    cfr."Tone",
    cfr."rToneFreq",
    cfr."cToneFreq",
    cfr."DtcsCode",
    cfr."DtcsPolarity",
    cfr."Mode",
    cfr."TStep",
    cfr."Skip",
    cfr."Comment",
    cfr."URCALL",
    cfr."RPT1CALL",
    cfr."RPT2CALL",
    cfr."DVCODE"
   FROM public.chirp_fm_raw cfr;


ALTER TABLE public.chirp_fm OWNER TO dz;

--
-- Name: dhm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dhm (
    rid integer NOT NULL,
    rast public.raster
);


ALTER TABLE public.dhm OWNER TO postgres;

--
-- Name: dhm_rid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dhm_rid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dhm_rid_seq OWNER TO postgres;

--
-- Name: dhm_rid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dhm_rid_seq OWNED BY public.dhm.rid;


--
-- Name: digital_repeater_id_import; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.digital_repeater_id_import (
    uid bigint NOT NULL,
    callsign character varying(10),
    station character varying,
    digital_id integer
);


ALTER TABLE public.digital_repeater_id_import OWNER TO dz;

--
-- Name: COLUMN digital_repeater_id_import.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.digital_repeater_id_import.uid IS 'UID';


--
-- Name: digital_repeater_id_import_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.digital_repeater_id_import_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.digital_repeater_id_import_uid_seq OWNER TO dz;

--
-- Name: digital_repeater_id_import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.digital_repeater_id_import_uid_seq OWNED BY public.digital_repeater_id_import.uid;


--
-- Name: dstar_at_import; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.dstar_at_import (
    uid integer NOT NULL,
    callsign character varying,
    site character varying,
    frequency_tx double precision,
    shift character varying,
    mode character varying,
    hardware character varying,
    rpt1 character varying,
    rpt2 character varying
);


ALTER TABLE public.dstar_at_import OWNER TO dz;

--
-- Name: COLUMN dstar_at_import.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.dstar_at_import.uid IS 'UID';


--
-- Name: dstar-import_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public."dstar-import_uid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."dstar-import_uid_seq" OWNER TO dz;

--
-- Name: dstar-import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public."dstar-import_uid_seq" OWNED BY public.dstar_at_import.uid;


--
-- Name: dstar-oevsv-import; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public."dstar-oevsv-import" (
    uid integer NOT NULL,
    id real,
    country character varying,
    callsign character varying,
    band character varying,
    datetime character varying,
    linkduration character varying,
    module character varying,
    ip character varying
);


ALTER TABLE public."dstar-oevsv-import" OWNER TO dz;

--
-- Name: COLUMN "dstar-oevsv-import".uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public."dstar-oevsv-import".uid IS 'UID';


--
-- Name: dstar-oevsv-import_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public."dstar-oevsv-import_uid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."dstar-oevsv-import_uid_seq" OWNER TO dz;

--
-- Name: dstar-oevsv-import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public."dstar-oevsv-import_uid_seq" OWNED BY public."dstar-oevsv-import".uid;


--
-- Name: echolink-import; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public."echolink-import" (
    uid integer NOT NULL,
    callsign character varying,
    welcome character varying,
    status character varying,
    "time" character varying,
    echolink_id integer
);


ALTER TABLE public."echolink-import" OWNER TO dz;

--
-- Name: COLUMN "echolink-import".uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public."echolink-import".uid IS 'UID';


--
-- Name: echolink_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.echolink_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.echolink_uid_seq OWNER TO dz;

--
-- Name: echolink_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.echolink_uid_seq OWNED BY public."echolink-import".uid;


--
-- Name: gd77_raw; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.gd77_raw AS
 SELECT concat("substring"((t.callsign)::text, 3, 4), '-', "substring"((public.band_name(t.frequency_tx))::text, 1, 1)) AS "Name",
    t.frequency_tx AS "Rx Freq",
    t.frequency_rx AS "Tx Freq",
    'Analog'::text AS "Ch Mode",
    'High'::text AS "Power",
    t.ctcss_rx AS "Rx Tone",
    t.ctcss_tx AS "Tx Tone",
    0 AS "Color Code",
    1 AS "Rx Group List",
    1 AS "Contact",
    1 AS "Repeater Slot"
   FROM public.trx t
  WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
  ORDER BY t.callsign, (public.band_name(t.frequency_tx));


ALTER TABLE public.gd77_raw OWNER TO dz;

--
-- Name: gd77; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.gd77 AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Number",
    g."Name",
    g."Rx Freq",
    g."Tx Freq",
    g."Ch Mode",
    g."Power",
    g."Rx Tone",
    g."Tx Tone",
    g."Color Code",
    g."Rx Group List",
    g."Contact",
    g."Repeater Slot"
   FROM public.gd77_raw g;


ALTER TABLE public.gd77 OWNER TO dz;

--
-- Name: import_hamnet_site; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.import_hamnet_site (
    uid bigint NOT NULL,
    id integer,
    "Name" character varying,
    callsign character varying,
    longitude double precision,
    latitude double precision,
    elevation integer,
    ground_asl integer,
    no_check integer,
    radioparam character varying,
    inactive integer,
    newcover integer,
    hascover integer,
    "Comment" character varying,
    maintainer character varying,
    rw_maint integer,
    editor character varying,
    edited character varying,
    "Version" integer,
    deleted integer,
    sea_level double precision,
    locator_short character varying(6),
    locator_long character varying(20),
    geo_prefix character varying(3),
    bev_gid integer,
    geom public.geometry(Geometry,3857),
    dummy character varying
);


ALTER TABLE public.import_hamnet_site OWNER TO dz;

--
-- Name: COLUMN import_hamnet_site.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.import_hamnet_site.uid IS 'UID';


--
-- Name: import_hamnet_site_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.import_hamnet_site_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_hamnet_site_uid_seq OWNER TO dz;

--
-- Name: import_hamnet_site_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.import_hamnet_site_uid_seq OWNED BY public.import_hamnet_site.uid;


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
-- Name: oesterreich_bev_vgd_lam; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oesterreich_bev_vgd_lam (
    gid integer NOT NULL,
    meridian smallint,
    gkz integer,
    bkz smallint,
    fa_nr smallint,
    bl_kz smallint,
    st_kz smallint,
    fl double precision,
    kg_nr character varying(6),
    kg character varying(50),
    pg character varying(50),
    pb character varying(50),
    fa character varying(50),
    gb_kz character varying(3),
    gb character varying(50),
    va_nr character varying(2),
    va character varying(50),
    bl character varying(50),
    st character varying(50),
    geom public.geometry(MultiPolygon,31287)
);


ALTER TABLE public.oesterreich_bev_vgd_lam OWNER TO postgres;

--
-- Name: oesterreich_bev_vgd_lam_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oesterreich_bev_vgd_lam_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oesterreich_bev_vgd_lam_gid_seq OWNER TO postgres;

--
-- Name: oesterreich_bev_vgd_lam_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oesterreich_bev_vgd_lam_gid_seq OWNED BY public.oesterreich_bev_vgd_lam.gid;


--
-- Name: packet_import; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.packet_import (
    uid integer NOT NULL,
    callsign character varying(6),
    frequency_rx double precision,
    frequency_tx double precision,
    location character varying(19),
    locator_import character varying(6),
    sea_level_import integer,
    sysop character varying(6),
    notes character varying(13),
    type_of_station character varying DEFAULT 'packet_radio'::character varying,
    other_mode boolean DEFAULT true,
    other_mode_name character varying,
    comment character varying
);


ALTER TABLE public.packet_import OWNER TO dz;

--
-- Name: packet_import_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.packet_import_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.packet_import_uid_seq OWNER TO dz;

--
-- Name: packet_import_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.packet_import_uid_seq OWNED BY public.packet_import.uid;


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

ALTER SEQUENCE public.repeater_uid_seq OWNED BY public.trx.uid;


--
-- Name: rt_ic9700_dr_dstar_raw; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.rt_ic9700_dr_dstar_raw AS
 SELECT t.frequency_tx AS "Receive Frequency",
    t.frequency_rx AS "Transmit Frequency",
    ' '::text AS "Offset Frequency",
    'DUP-'::text AS "Offset Direction",
    'On'::text AS "Repeater Use",
    'DV'::text AS "Operating Mode",
    public.nice_display(t.site_name) AS "Name",
    concat(t.callsign, ' ', t.dstar_rpt1) AS "Sub Name",
    'None'::text AS "Tone Mode",
    '67.0 Hz'::text AS "CTCSS",
    ''::text AS "IP Address",
    concat(t.callsign, ' ', t.dstar_rpt1) AS "Rpt-1 CallSign",
    concat(t.callsign, ' ', t.dstar_rpt2) AS "Rpt-2 CallSign",
    'Exact'::text AS "LatLng",
    concat(public.nice_geo_dms(s.latitude), 'N') AS "Latitude",
    concat(public.nice_geo_dms(s.longitude), 'E') AS "Longitude",
    '+01:00'::text AS "UTC Offset",
    '1: Austria'::text AS "Bank",
    ''::text AS "Comment",
    ''::text AS "Dummy"
   FROM (public.trx t
     LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
  WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dstar = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
  ORDER BY t.callsign, (public.band_name(t.frequency_tx));


ALTER TABLE public.rt_ic9700_dr_dstar_raw OWNER TO dz;

--
-- Name: rt_ic9700_dr_fm_raw; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.rt_ic9700_dr_fm_raw AS
 SELECT t.frequency_tx AS "Receive Frequency",
    t.frequency_rx AS "Transmit Frequency",
    ' '::text AS "Offset Frequency",
    'DUP-'::text AS "Offset Direction",
    'On'::text AS "Repeater Use",
    'FM'::text AS "Operating Mode",
    public.nice_display(t.site_name) AS "Name",
    ''::text AS "Sub Name",
        CASE
            WHEN ((t.ctcss_tx IS NOT NULL) AND (t.ctcss_rx IS NULL)) THEN 'TSQL'::text
            WHEN (t.ctcss_rx IS NOT NULL) THEN 'Tone'::text
            ELSE 'None'::text
        END AS "Tone Mode",
        CASE
            WHEN (t.ctcss_rx IS NULL) THEN ''::text
            ELSE concat(to_char(t.ctcss_rx, '999.9'::text), ' Hz')
        END AS "CTCSS",
    ''::text AS "IP Address",
    ''::text AS "Rpt-1 CallSign",
    ''::text AS "Rpt-2 CallSign",
    'Exact'::text AS "LatLng",
    concat(public.nice_geo_dms(s.latitude), 'N') AS "Latitude",
    concat(public.nice_geo_dms(s.longitude), 'E') AS "Longitude",
    '+01:00'::text AS "UTC Offset",
    '1: Austria'::text AS "Bank",
    ''::text AS "Comment",
    ''::text AS "Dummy"
   FROM (public.trx t
     LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
  WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text) AND (t.frequency_tx > (144)::double precision) AND (t.frequency_tx < (440)::double precision))
  ORDER BY t.callsign, (public.band_name(t.frequency_tx));


ALTER TABLE public.rt_ic9700_dr_fm_raw OWNER TO dz;

--
-- Name: rt_ic9700_dr; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.rt_ic9700_dr AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Channel Number",
    foobar."Receive Frequency",
    foobar."Transmit Frequency",
    foobar."Offset Frequency",
    foobar."Offset Direction",
    foobar."Repeater Use",
    foobar."Operating Mode",
    foobar."Name",
    foobar."Sub Name",
    foobar."Tone Mode",
    foobar."CTCSS",
    foobar."IP Address",
    foobar."Rpt-1 CallSign",
    foobar."Rpt-2 CallSign",
    foobar."LatLng",
    foobar."Latitude",
    foobar."Longitude",
    foobar."UTC Offset",
    foobar."Bank",
    foobar."Comment",
    foobar."Dummy"
   FROM ( SELECT r."Receive Frequency",
            r."Transmit Frequency",
            r."Offset Frequency",
            r."Offset Direction",
            r."Repeater Use",
            r."Operating Mode",
            r."Name",
            r."Sub Name",
            r."Tone Mode",
            r."CTCSS",
            r."IP Address",
            r."Rpt-1 CallSign",
            r."Rpt-2 CallSign",
            r."LatLng",
            r."Latitude",
            r."Longitude",
            r."UTC Offset",
            r."Bank",
            r."Comment",
            r."Dummy"
           FROM public.rt_ic9700_dr_dstar_raw r
        UNION
         SELECT r."Receive Frequency",
            r."Transmit Frequency",
            r."Offset Frequency",
            r."Offset Direction",
            r."Repeater Use",
            r."Operating Mode",
            r."Name",
            r."Sub Name",
            r."Tone Mode",
            r."CTCSS",
            r."IP Address",
            r."Rpt-1 CallSign",
            r."Rpt-2 CallSign",
            r."LatLng",
            r."Latitude",
            r."Longitude",
            r."UTC Offset",
            r."Bank",
            r."Comment",
            r."Dummy"
           FROM public.rt_ic9700_dr_fm_raw r) foobar;


ALTER TABLE public.rt_ic9700_dr OWNER TO dz;

--
-- Name: rt_ic9700_fm_raw; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.rt_ic9700_fm_raw AS
 SELECT t.frequency_tx AS "Receive Frequency",
    t.frequency_rx AS "Transmit Frequency",
    ' '::text AS "Offset Frequency",
    'DUP-'::text AS "Offset Direction",
    'FM'::text AS "Operating Mode",
    ''::text AS "Data Mode",
    '1'::text AS "Filter",
    (public.nice_display(t.site_name))::text AS "Name",
        CASE
            WHEN ((t.ctcss_tx IS NOT NULL) AND (t.ctcss_rx IS NULL)) THEN 'TSQL'::text
            WHEN (t.ctcss_rx IS NOT NULL) THEN 'Tone'::text
            ELSE 'None'::text
        END AS "Tone Mode",
        CASE
            WHEN (t.ctcss_rx IS NULL) THEN ''::text
            ELSE concat(to_char(t.ctcss_rx, '999.9'::text), ' Hz')
        END AS "CTCSS",
        CASE
            WHEN (t.ctcss_tx IS NULL) THEN ''::text
            ELSE concat(to_char(t.ctcss_tx, '999.9'::text), ' Hz')
        END AS "Rx CTCSS",
    '023'::text AS "DCS",
    'Both N'::text AS "DCS Polarity",
    ''::text AS "Scan Select",
    'Off'::text AS "Digital Squelch",
    '0'::text AS "Digital Code",
    'CQCQCQ'::text AS "Your Callsign",
    ''::text AS "Rpt-1 CallSign",
    ''::text AS "Rpt-2 CallSign",
    concat(t.callsign, ' ', public.nice_display(s.city), ' ', public.nice_display(t.site_name)) AS "Comment",
    ''::text AS "Dummy"
   FROM (public.trx t
     LEFT JOIN public.site s ON (((t.site_name)::text = (s.site_name)::text)))
  WHERE (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true) AND ((t.status)::text = 'active'::text))
  ORDER BY ROW(public.band_name(t.frequency_tx), t.callsign);


ALTER TABLE public.rt_ic9700_fm_raw OWNER TO dz;

--
-- Name: rt_ic9700_fm; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.rt_ic9700_fm AS
 SELECT row_number() OVER (PARTITION BY true::boolean) AS "Channel Number",
    rt."Receive Frequency",
    rt."Transmit Frequency",
    rt."Offset Frequency",
    rt."Offset Direction",
    rt."Operating Mode",
    rt."Data Mode",
    rt."Filter",
    rt."Name",
    rt."Tone Mode",
    rt."CTCSS",
    rt."Rx CTCSS",
    rt."DCS",
    rt."DCS Polarity",
    rt."Scan Select",
    rt."Digital Squelch",
    rt."Digital Code",
    rt."Your Callsign",
    rt."Rpt-1 CallSign",
    rt."Rpt-2 CallSign",
    rt."Comment",
    rt."Dummy"
   FROM public.rt_ic9700_fm_raw rt;


ALTER TABLE public.rt_ic9700_fm OWNER TO dz;

--
-- Name: setting_options_uid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.setting_options_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.setting_options_uid_seq OWNER TO postgres;

--
-- Name: setting_options_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.setting_options_uid_seq OWNED BY public.setting_options.uid;


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
-- Name: site_callsigns_atv; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_atv AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE (((trx.type_of_station)::text = 'atv'::text) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_atv OWNER TO dz;

--
-- Name: site_callsigns_beacon; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_callsigns_beacon AS
 SELECT s.uid,
    s.geom,
    s.site_name AS name,
    s.city,
    string_agg(DISTINCT (trx.callsign)::text, ' '::text ORDER BY (trx.callsign)::text) AS callsigns,
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
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
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
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
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
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
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
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
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
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
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
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
    string_agg(DISTINCT (public.nice_frq(trx.frequency_tx))::text, '/'::text ORDER BY (public.nice_frq(trx.frequency_tx))::text) AS frequencies_tx
   FROM (public.site s
     LEFT JOIN public.trx ON (((s.site_name)::text = (trx.site_name)::text)))
  WHERE ((trx.tetra = true) AND ((trx.status)::text = 'active'::text))
  GROUP BY s.site_name, s.geom, s.city, s.uid;


ALTER TABLE public.site_callsigns_tetra OWNER TO dz;

--
-- Name: site_list; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.site_list AS
 SELECT s.site_name AS "Site name",
    s.city AS "City",
    public.maidenhead_loc(s.longitude, s.latitude) AS "Loc short",
    public.maidenhead_loc(s.longitude, s.latitude, 6) AS "Loc long",
    public.nice_geo(s.longitude) AS "Longitude",
    public.nice_geo(s.latitude) AS "Latitude",
    to_char(s.longitude, '990.999999'::text) AS "Long dez",
    to_char(s.latitude, '990.999999'::text) AS "Lat dez",
    string_agg(DISTINCT (t.callsign)::text, ' '::text ORDER BY (t.callsign)::text) AS "Callsigns"
   FROM (public.site s
     LEFT JOIN public.trx t ON (((s.site_name)::text = (t.site_name)::text)))
  WHERE ((t.status)::text = 'active'::text)
  GROUP BY s.site_name, s.geom, s.city, s.geo_prefix, s.latitude, s.longitude
  ORDER BY s.site_name;


ALTER TABLE public.site_list OWNER TO dz;

--
-- Name: srv07_mapping; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.srv07_mapping (
    uid integer NOT NULL,
    callsign character varying(10) NOT NULL,
    frequency_tx double precision NOT NULL,
    frequency_srv07 double precision NOT NULL
);


ALTER TABLE public.srv07_mapping OWNER TO dz;

--
-- Name: COLUMN srv07_mapping.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.srv07_mapping.uid IS 'UID';


--
-- Name: COLUMN srv07_mapping.callsign; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.srv07_mapping.callsign IS 'Callsign of mapped station';


--
-- Name: COLUMN srv07_mapping.frequency_tx; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.srv07_mapping.frequency_tx IS 'Frequency according to repeater table (correct frequency)';


--
-- Name: COLUMN srv07_mapping.frequency_srv07; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.srv07_mapping.frequency_srv07 IS 'Frequency according to src07 (IPSC2)';


--
-- Name: srv07_mapping_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.srv07_mapping_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.srv07_mapping_uid_seq OWNER TO dz;

--
-- Name: srv07_mapping_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.srv07_mapping_uid_seq OWNED BY public.srv07_mapping.uid;


--
-- Name: srv07_status; Type: TABLE; Schema: public; Owner: dz
--

CREATE TABLE public.srv07_status (
    uid integer NOT NULL,
    protocol character varying(5),
    digital_id bigint,
    callsign character varying(8),
    default_group integer,
    qual integer,
    frequency_tx double precision,
    frequency_offset double precision,
    registered integer,
    extra_col character varying(50)
);


ALTER TABLE public.srv07_status OWNER TO dz;

--
-- Name: COLUMN srv07_status.uid; Type: COMMENT; Schema: public; Owner: dz
--

COMMENT ON COLUMN public.srv07_status.uid IS 'UID';


--
-- Name: srv07_status_uid_seq; Type: SEQUENCE; Schema: public; Owner: dz
--

CREATE SEQUENCE public.srv07_status_uid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.srv07_status_uid_seq OWNER TO dz;

--
-- Name: srv07_status_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dz
--

ALTER SEQUENCE public.srv07_status_uid_seq OWNED BY public.srv07_status.uid;


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

ALTER SEQUENCE public.station_uid_seq OWNED BY public.site.uid;


--
-- Name: trx_list; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list AS
 SELECT public.band_name(t.frequency_tx) AS band,
    public.channel_name(t.frequency_tx, t.frequency_rx, 0) AS ch,
    public.channel_name(t.frequency_tx, t.frequency_rx, 1) AS ch_new,
    t.uid,
    t.type_of_station,
    t.frequency_tx,
    t.frequency_rx,
    t.callsign,
    t.antenna_heigth,
    t.site_name,
    t.sysop,
    t.url,
    t.hardware,
    t.mmdvm,
    t.solar_power,
    t.battery_power,
    t.status,
    t.fm,
    t.fm_wakeup,
    t.ctcss_tx,
    t.ctcss_rx,
    t.echolink,
    t.echolink_id,
    t.digital_id,
    t.dmr,
    t.ipsc2,
    t.brandmeister,
    t.network_registered,
    t.c4fm,
    t.c4fm_groups,
    t.dstar,
    t.dstar_rpt1,
    t.dstar_rpt2,
    t.tetra,
    t.other_mode,
    t.other_mode_name,
    t.comment,
    t.created_at,
    s.city,
    s.longitude,
    s.latitude,
    s.sea_level,
    s.locator_short,
    s.locator_long,
    s.geo_prefix,
    s.bev_gid,
    s.geom,
    o.kg,
    o.pg,
    o.bl,
    t.cc,
    concat("substring"((t.callsign)::text, 3, 4), '-',
        CASE
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.fm = true)) THEN
            CASE
                WHEN ((public.band_name(t.frequency_tx))::text = '6m'::text) THEN '6'::text
                WHEN ((public.band_name(t.frequency_tx))::text = '2m'::text) THEN '2'::text
                WHEN ((public.band_name(t.frequency_tx))::text = '70cm'::text) THEN '7'::text
                WHEN ((public.band_name(t.frequency_tx))::text = '23cm'::text) THEN '3'::text
                WHEN ((public.band_name(t.frequency_tx))::text = '13cm'::text) THEN '1'::text
                ELSE '0'::text
            END
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dmr = true)) THEN 'D'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.c4fm = true)) THEN 'C'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.dstar = true)) THEN 'I'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.tetra = true)) THEN 'T'::text
            WHEN (((t.type_of_station)::text = 'repeater_voice'::text) AND (t.other_mode = true)) THEN 'X'::text
            WHEN ((t.type_of_station)::text = 'atv'::text) THEN 'A'::text
            WHEN ((t.type_of_station)::text = 'digipeater'::text) THEN 'P'::text
            WHEN ((t.type_of_station)::text = 'beacon'::text) THEN 'B'::text
            ELSE 'N'::text
        END) AS label
   FROM ((public.trx t
     LEFT JOIN public.site s ON (((s.site_name)::text = (t.site_name)::text)))
     LEFT JOIN public.oesterreich_bev_vgd_lam o ON ((o.gid = s.bev_gid)))
  WHERE ((t.status)::text = 'active'::text)
  ORDER BY s.geo_prefix, t.frequency_tx;


ALTER TABLE public.trx_list OWNER TO dz;

--
-- Name: trx_list_atv; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_atv AS
 SELECT COALESCE(t.band, public.band_name(t.frequency_rx)) AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    public.nice_frq(t.frequency_rx) AS "Frquency RX",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.other_mode_name AS "Mode",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE ((t.type_of_station)::text = 'atv'::text);


ALTER TABLE public.trx_list_atv OWNER TO dz;

--
-- Name: trx_list_beacon; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_beacon AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    t.sysop AS "Sysop",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.locator_long AS "Locator",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE ((t.type_of_station)::text = 'beacon'::text);


ALTER TABLE public.trx_list_beacon OWNER TO dz;

--
-- Name: trx_list_c4fm; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_c4fm AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    public.nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    btrim(concat(t.comment,
        CASE
            WHEN (t.comment IS NOT NULL) THEN ','::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.mmdvm = true) THEN 'MMDVM '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.c4fm_groups IS NOT NULL) THEN (t.c4fm_groups)::text
            ELSE NULL::text
        END)) AS "Comment"
   FROM public.trx_list t
  WHERE (t.c4fm = true);


ALTER TABLE public.trx_list_c4fm OWNER TO dz;

--
-- Name: trx_list_digipeater; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_digipeater AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    public.nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.other_mode_name AS "Mode",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE ((t.type_of_station)::text = 'digipeater'::text);


ALTER TABLE public.trx_list_digipeater OWNER TO dz;

--
-- Name: trx_list_dmr; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_dmr AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    public.nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.digital_id AS "Digital ID",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    btrim(concat(t.comment,
        CASE
            WHEN ((t.cc IS NOT NULL) AND (t.cc <> 1)) THEN concat('CC=', t.cc, ' ')
            ELSE NULL::text
        END,
        CASE
            WHEN (t.comment IS NOT NULL) THEN ','::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.ipsc2 = true) THEN 'IPSC2 '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.brandmeister = true) THEN 'BM '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.mmdvm = true) THEN 'MMDVM '::text
            ELSE NULL::text
        END)) AS "Comment"
   FROM public.trx_list t
  WHERE (t.dmr = true);


ALTER TABLE public.trx_list_dmr OWNER TO dz;

--
-- Name: trx_list_dstar; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_dstar AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    public.nice_frq(t.frequency_rx) AS "Frquency RX",
    t.ch AS "Ch",
    t.sysop AS "Sysop",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    btrim(concat(t.comment,
        CASE
            WHEN (t.comment IS NOT NULL) THEN ' '::text
            ELSE NULL::text
        END,
        CASE
            WHEN (t.mmdvm = true) THEN 'MMDVM '::text
            ELSE NULL::text
        END)) AS "Comment"
   FROM public.trx_list t
  WHERE (t.dstar = true);


ALTER TABLE public.trx_list_dstar OWNER TO dz;

--
-- Name: trx_list_fm; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_fm AS
 SELECT t.band AS "Band",
    t.label AS "Label",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    t.frequency_tx AS "Frequency TX",
    t.frequency_rx AS "Frequency RX",
    t.ch AS "Ch",
    t.ctcss_tx AS "CTCSS TX",
    t.ctcss_rx AS "CTCSS RX",
    t.fm_wakeup AS "Wakeup",
    t.sysop AS "Sysop",
    t.echolink_id AS "Echolink",
    t.comment AS "Comment",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel"
   FROM public.trx_list t
  WHERE (t.fm = true);


ALTER TABLE public.trx_list_fm OWNER TO dz;

--
-- Name: trx_list_tetra; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_list_tetra AS
 SELECT t.band AS "Band",
    t.callsign AS "Callsign",
    t.city AS "City",
    t.site_name AS "Site",
    public.nice_frq(t.frequency_tx) AS "Frequency TX",
    public.nice_frq(t.frequency_rx) AS "Frquency RX",
    t.hardware AS "Hardware",
    t.sysop AS "Sysop",
    public.nice_geo(t.longitude) AS "Longitude",
    public.nice_geo(t.latitude) AS "Latitude",
    t.sea_level AS "Sealevel",
    t.comment AS "Comment"
   FROM public.trx_list t
  WHERE (t.tetra = true);


ALTER TABLE public.trx_list_tetra OWNER TO dz;

--
-- Name: trx_verylong; Type: VIEW; Schema: public; Owner: dz
--

CREATE VIEW public.trx_verylong AS
 SELECT public.band_name(t.frequency_tx) AS band,
    public.channel_name(t.frequency_tx, t.frequency_rx, 0) AS ch,
    public.channel_name(t.frequency_tx, t.frequency_rx, 1) AS ch_new,
    t.uid,
    t.type_of_station,
    t.frequency_tx,
    t.frequency_rx,
    t.callsign,
    t.antenna_heigth,
    t.site_name,
    t.sysop,
    t.url,
    t.hardware,
    t.mmdvm,
    t.solar_power,
    t.battery_power,
    t.status,
    t.fm,
    t.fm_wakeup,
    t.ctcss_tx,
    t.ctcss_rx,
    t.echolink,
    t.echolink_id,
    t.digital_id,
    t.dmr,
    t.cc,
    t.ipsc2,
    t.brandmeister,
    t.network_registered,
    t.c4fm,
    t.c4fm_groups,
    t.dstar,
    t.dstar_rpt1,
    t.dstar_rpt2,
    t.tetra,
    t.other_mode,
    t.other_mode_name,
    t.comment,
    t.created_at,
    s.city,
    s.longitude,
    s.latitude,
    s.sea_level,
    s.locator_short,
    s.locator_long,
    s.geo_prefix,
    s.bev_gid,
    s.geom,
    l.name_address,
    o.gkz,
    o.bkz,
    o.kg,
    o.pg,
    o.bl
   FROM (((public.trx t
     LEFT JOIN public.site s ON (((s.site_name)::text = (t.site_name)::text)))
     LEFT JOIN public.licenses l ON (((t.callsign)::text = (l.callsign)::text)))
     LEFT JOIN public.oesterreich_bev_vgd_lam o ON ((o.gid = s.bev_gid)));


ALTER TABLE public.trx_verylong OWNER TO dz;

--
-- Name: bands uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.bands ALTER COLUMN uid SET DEFAULT nextval('public.band_uid_seq'::regclass);


--
-- Name: beacon_import uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.beacon_import ALTER COLUMN uid SET DEFAULT nextval('public.beacon_import_uid_seq'::regclass);


--
-- Name: bl_kz_prefix uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.bl_kz_prefix ALTER COLUMN uid SET DEFAULT nextval('public.bl_kz_prefix_uid_seq'::regclass);


--
-- Name: dhm rid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dhm ALTER COLUMN rid SET DEFAULT nextval('public.dhm_rid_seq'::regclass);


--
-- Name: digital_repeater_id_import uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.digital_repeater_id_import ALTER COLUMN uid SET DEFAULT nextval('public.digital_repeater_id_import_uid_seq'::regclass);


--
-- Name: dstar-oevsv-import uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public."dstar-oevsv-import" ALTER COLUMN uid SET DEFAULT nextval('public."dstar-oevsv-import_uid_seq"'::regclass);


--
-- Name: dstar_at_import uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.dstar_at_import ALTER COLUMN uid SET DEFAULT nextval('public."dstar-import_uid_seq"'::regclass);


--
-- Name: echolink-import uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public."echolink-import" ALTER COLUMN uid SET DEFAULT nextval('public.echolink_uid_seq'::regclass);


--
-- Name: import_hamnet_site uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.import_hamnet_site ALTER COLUMN uid SET DEFAULT nextval('public.import_hamnet_site_uid_seq'::regclass);


--
-- Name: licenses uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.licenses ALTER COLUMN uid SET DEFAULT nextval('public.licenses_uid_seq'::regclass);


--
-- Name: oesterreich_bev_vgd_lam gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oesterreich_bev_vgd_lam ALTER COLUMN gid SET DEFAULT nextval('public.oesterreich_bev_vgd_lam_gid_seq'::regclass);


--
-- Name: packet_import uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.packet_import ALTER COLUMN uid SET DEFAULT nextval('public.packet_import_uid_seq'::regclass);


--
-- Name: setting_options uid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.setting_options ALTER COLUMN uid SET DEFAULT nextval('public.setting_options_uid_seq'::regclass);


--
-- Name: site uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.site ALTER COLUMN uid SET DEFAULT nextval('public.station_uid_seq'::regclass);


--
-- Name: srv07_mapping uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.srv07_mapping ALTER COLUMN uid SET DEFAULT nextval('public.srv07_mapping_uid_seq'::regclass);


--
-- Name: srv07_status uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.srv07_status ALTER COLUMN uid SET DEFAULT nextval('public.srv07_status_uid_seq'::regclass);


--
-- Name: trx uid; Type: DEFAULT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.trx ALTER COLUMN uid SET DEFAULT nextval('public.repeater_uid_seq'::regclass);


--
-- Name: dhm dhm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dhm
    ADD CONSTRAINT dhm_pkey PRIMARY KEY (rid);


--
-- Name: oesterreich_bev_vgd_lam oesterreich_bev_vgd_lam_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oesterreich_bev_vgd_lam
    ADD CONSTRAINT oesterreich_bev_vgd_lam_pkey PRIMARY KEY (gid);


--
-- Name: import_hamnet_site pk_import_hamnet_site; Type: CONSTRAINT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.import_hamnet_site
    ADD CONSTRAINT pk_import_hamnet_site PRIMARY KEY (uid);


--
-- Name: site pk_site; Type: CONSTRAINT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.site
    ADD CONSTRAINT pk_site PRIMARY KEY (uid);


--
-- Name: trx trx_pk; Type: CONSTRAINT; Schema: public; Owner: dz
--

ALTER TABLE ONLY public.trx
    ADD CONSTRAINT trx_pk PRIMARY KEY (uid);


--
-- Name: band_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX band_uid_idx ON public.bands USING btree (uid);


--
-- Name: beacon_import_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX beacon_import_uid_idx ON public.beacon_import USING btree (uid);


--
-- Name: dhm_st_convexhull_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dhm_st_convexhull_idx ON public.dhm USING gist (public.st_convexhull(rast));


--
-- Name: digital_repeater_id_import_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX digital_repeater_id_import_uid_idx ON public.digital_repeater_id_import USING btree (uid);


--
-- Name: dstar_import_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX dstar_import_uid_idx ON public.dstar_at_import USING btree (uid);


--
-- Name: dstar_oevsv_import_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX dstar_oevsv_import_uid_idx ON public."dstar-oevsv-import" USING btree (uid);


--
-- Name: echolink_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX echolink_uid_idx ON public."echolink-import" USING btree (uid);


--
-- Name: import_hamnet_site_geom_gix; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX import_hamnet_site_geom_gix ON public.import_hamnet_site USING gist (geom);


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
-- Name: oesterreich_bev_vgd_lam_geom_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX oesterreich_bev_vgd_lam_geom_idx ON public.oesterreich_bev_vgd_lam USING gist (geom);


--
-- Name: site_geom_gix; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX site_geom_gix ON public.site USING gist (geom);


--
-- Name: site_name_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE UNIQUE INDEX site_name_idx ON public.site USING btree (site_name);


--
-- Name: srv07_mapping_uid_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX srv07_mapping_uid_idx ON public.srv07_mapping USING btree (uid);


--
-- Name: trx_c4fm_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_c4fm_idx ON public.trx USING btree (c4fm);


--
-- Name: trx_callsign_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_callsign_idx ON public.trx USING btree (callsign);


--
-- Name: trx_dmr_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_dmr_idx ON public.trx USING btree (dmr);


--
-- Name: trx_dstar_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_dstar_idx ON public.trx USING btree (dstar);


--
-- Name: trx_fm_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_fm_idx ON public.trx USING btree (fm);


--
-- Name: trx_frequency_tx_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_frequency_tx_idx ON public.trx USING btree (frequency_tx);


--
-- Name: trx_other_mode_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_other_mode_idx ON public.trx USING btree (other_mode);


--
-- Name: trx_site_name_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_site_name_idx ON public.trx USING btree (site_name);


--
-- Name: trx_tetra_idx; Type: INDEX; Schema: public; Owner: dz
--

CREATE INDEX trx_tetra_idx ON public.trx USING btree (tetra);


--
-- Name: import_hamnet_site import_hamnet_site_trigger; Type: TRIGGER; Schema: public; Owner: dz
--

CREATE TRIGGER import_hamnet_site_trigger BEFORE INSERT OR UPDATE ON public.import_hamnet_site FOR EACH ROW EXECUTE FUNCTION public.trigger_import_hamnet_site();


--
-- Name: site site_trigger; Type: TRIGGER; Schema: public; Owner: dz
--

CREATE TRIGGER site_trigger BEFORE INSERT OR UPDATE ON public.site FOR EACH ROW EXECUTE FUNCTION public.trigger_site();


--
-- Name: SCHEMA api; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA api TO web_anon;
GRANT ALL ON SCHEMA api TO dz;


--
-- Name: TABLE setting_options; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.setting_options TO dz;


--
-- Name: TABLE settings; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.settings TO dz;
GRANT SELECT ON TABLE api.settings TO web_anon;


--
-- Name: TABLE site; Type: ACL; Schema: api; Owner: dz
--

GRANT SELECT ON TABLE api.site TO web_anon;


--
-- Name: TABLE trx; Type: ACL; Schema: api; Owner: dz
--

GRANT SELECT ON TABLE api.trx TO web_anon;


--
-- Name: TABLE bands; Type: ACL; Schema: public; Owner: dz
--

GRANT SELECT ON TABLE public.bands TO web_anon;


--
-- Name: TABLE dhm; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.dhm TO dz;


--
-- Name: TABLE oesterreich_bev_vgd_lam; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.oesterreich_bev_vgd_lam TO dz;


--
-- PostgreSQL database dump complete
--

