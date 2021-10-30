

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
