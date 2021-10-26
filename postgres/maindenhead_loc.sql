-- PostgeSQL function to convert latitude/longitude into Maidenhead Locator
-- OE3DZW, APL2.0
-- Usage: maidenhead_loc(latitude,longitude[,pairs])
-- pairs: The number of digit pairs, the default is 3, e.g. JN78ab


--
-- Name: maidenhead_loc(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.maidenhead_loc(latitude double precision, longitude double precision) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      
   BEGIN
     -- short default locator (3 pairs aka 6 digits
     RETURN  maidenhead_loc (latitude,longitude,3);
   END
$$;


ALTER FUNCTION public.maidenhead_loc(latitude double precision, longitude double precision) OWNER TO postgres;

--
-- Name: maidenhead_loc(double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.maidenhead_loc(latitude double precision, longitude double precision, pairs integer) RETURNS character varying
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


ALTER FUNCTION public.maidenhead_loc(latitude double precision, longitude double precision, pairs integer) OWNER TO postgres;

