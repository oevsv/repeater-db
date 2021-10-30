
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

