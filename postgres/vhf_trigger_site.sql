
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

           -- set see level
           SELECT INTO NEW.see_level ST_Value(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)))
           FROM dhm WHERE st_intersects(rast, (ST_Transform(ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326), 31287)));   
           NEW.see_level = round(NEW.see_level);
           
           -- set geo prefix according to region
           SELECT map.prefix,bev.gid
                INTO NEW.geo_prefix, new.bev_gid
                FROM oesterreich_bev_vgd_lam as bev
                LEFT JOIN bl_kz_prefix map on map.bl_kz=bev.bl_kz, station as r
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

--
-- Name: trigger_station(); Type: FUNCTION; Schema: public; Owner: dz
--
