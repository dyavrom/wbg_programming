dtj = dbGetQuery(conn, "SELECT
to_number(hreport_univ5.region) as region,
location_state state,
hreport_univ5.handler_id,
handler_name,
--SUBSTR( permit_expiration_date, 1, 4) || '-' || SUBSTR( permit_expiration_date, 5, 2) || '-' ||SUBSTR( permit_expiration_date, 7, 2) max_handler_exp_date,
TO_CHAR(TO_DATE( SUBSTR( permit_expiration_date, 1, 8), 'YYYYMMDD'), 'MM/DD/YYYY') 
max_handler_exp_date, 
TO_CHAR(
  CASE 
  WHEN op_and_pc_permits.handler_id IS NOT NULL THEN 'BOTH'
  WHEN SUBSTR(permit_expiration_date,1,8) IS NULL THEN null
  ELSE  SUBSTR( permit_expiration_date, 9, 3)
  END 
) max_handler_exp_permit_type,  
permit_expiration_date_unit unit_exp_date,
max_permit_date,
--max_permit_event_code,
substr(permit_info,9,7) event_Code,
current_unit.unit_seq,
punit4.unit_name,
unit_detail_seq,
DECODE (state_workload_information.handler_id,
        null, 'Y',
        'N'
) state_renewal,
legal_operating_status,
to_char(effective_date, 'MM/DD/YYYY') effective_date,
location_street1,
location_city,
DECODE ( substr(permit_info,14,2),
         'CA', 'Y',
         'N'
) ca_permit_only 

FROM 
rcrainfo.hreport_univ5

JOIN                  
(SELECT 
  handler_id,
  unit_seq,
  unit_detail_seq,
  effective_date,
  legal_operating_status
  
  FROM 
  punit_detail4
  
  WHERE
  current_unit_detail = 'Y'      
)  current_unit
ON hreport_univ5.handler_id = current_unit.handler_id

JOIN punit4
ON  (current_unit.handler_id = punit4.handler_id
     AND  current_unit.unit_seq = punit4.unit_seq)


LEFT JOIN 
(SELECT 
  handler_id,
  unit_seq,
  MAX(COALESCE(schedule_date_new, schedule_date_orig, actual_date) ) permit_expiration_date_unit
  
  FROM 
  pevent4
  
  JOIN pln_event_unit_detail4
  ON (pevent4.handler_id = pln_event_unit_detail4.event_handler_id
      AND pevent4.series_seq = pln_event_unit_detail4.event_series_seq
      AND pevent4.event_activity_location = pln_event_unit_detail4.event_activity_location
      AND pevent4.event_seq = pln_event_unit_detail4.event_seq
      AND pevent4.event_agency = pln_event_unit_detail4.event_agency
      AND pevent4.event_owner = pln_event_unit_detail4.event_owner
      AND pevent4.event_code = pln_event_unit_detail4.event_code)
  
  WHERE 
  SUBSTR(pevent4.event_code,1,5) IN ('OP270', 'PC270')
  
  GROUP BY 
  handler_id,
  unit_seq
) permit_expiration_unit
ON  (hreport_univ5.handler_id = permit_expiration_unit.handler_id 
     AND  current_unit.unit_seq = permit_expiration_unit.unit_seq)

LEFT JOIN 
(SELECT 
  handler_id,
  MAX(actual_date) max_permit_date
  
  FROM 
  pevent4
  
  JOIN pln_event_unit_detail4
  ON (pevent4.handler_id = pln_event_unit_detail4.event_handler_id
      AND pevent4.series_seq = pln_event_unit_detail4.event_series_seq
      AND pevent4.event_activity_location = pln_event_unit_detail4.event_activity_location
      AND pevent4.event_seq = pln_event_unit_detail4.event_seq
      AND pevent4.event_agency = pln_event_unit_detail4.event_agency
      AND pevent4.event_owner = pln_event_unit_detail4.event_owner
      AND pevent4.event_code = pln_event_unit_detail4.event_code)
  
  WHERE 
  SUBSTR(pevent4.event_code,1,5) IN ('OP200', 'PC200')
  AND SUBSTR(pevent4.event_code,6,2) <> 'PD'
  
  GROUP BY 
  handler_id 
) permit
ON (hreport_univ5.handler_id = permit.handler_id) 

LEFT JOIN 
(SELECT 
  handler_id,
  MAX(TO_CHAR(COALESCE(schedule_date_new, schedule_date_orig, actual_date), 'YYYYMMDD') || 
        CASE
      WHEN SUBSTR(pevent4.event_code,1,5) = 'OP270' THEN 'OPU'
      WHEN SUBSTR(pevent4.event_code,1,5) = 'PC270' THEN 'PCU'
      END
  ) permit_expiration_date,
  fn_get_fy(MAX(COALESCE(schedule_date_new, schedule_date_orig, actual_date) ) )  permit_expiration_fy
  
  FROM 
  pevent4
  
  JOIN pln_event_unit_detail4
  ON (pevent4.handler_id = pln_event_unit_detail4.event_handler_id
      AND pevent4.series_seq = pln_event_unit_detail4.event_series_seq
      AND pevent4.event_activity_location = pln_event_unit_detail4.event_activity_location
      AND pevent4.event_seq = pln_event_unit_detail4.event_seq
      AND pevent4.event_agency = pln_event_unit_detail4.event_agency
      AND pevent4.event_owner = pln_event_unit_detail4.event_owner
      AND pevent4.event_code = pln_event_unit_detail4.event_code)            
  
  WHERE 
  SUBSTR(pevent4.event_code,1,5) IN ('OP270', 'PC270')
  AND (handler_id, unit_seq) IN 
  (SELECT DISTINCT 
    handler_id, 
    unit_seq
    
    FROM 
    (SELECT 
      handler_id,
      unit_seq,
      unit_detail_seq,
      effective_date,
      legal_operating_status
      
      FROM 
      punit_detail4
      
      WHERE
      current_unit_detail = 'Y'     
    )
    WHERE SUBSTR(legal_operating_status,1,2) IN ('PI', 'PC', 'PM')
    AND SUBSTR(legal_operating_status,3,2) IN ('OP', 'IN', 'CP', 'DC', 'NE', 'CA', 'CN', 'UC', 'BC', 'AE') 
  )           
  
  GROUP BY 
  handler_id 
) permit_expiration
ON hreport_univ5.handler_id = permit_expiration.handler_id 

LEFT JOIN 
(SELECT 
  handler_id,
  COUNT(*) both
  
  FROM           
  (SELECT 
    handler_id,
    CASE
    WHEN SUBSTR(pevent4.event_code,1,5) = 'OP270' THEN 'OPU'
    WHEN SUBSTR(pevent4.event_code,1,5) = 'PC270' THEN 'PCU'
    END permit_expiration_date_type,
    MAX(TO_CHAR(best_date, 'YYYYMMDD') ) permit_expiration_date
    
    FROM 
    pevent4
    
    JOIN pln_event_unit_detail4
    ON (pevent4.handler_id = pln_event_unit_detail4.event_handler_id
        AND pevent4.series_seq = pln_event_unit_detail4.event_series_seq
        AND pevent4.event_activity_location = pln_event_unit_detail4.event_activity_location
        AND pevent4.event_seq = pln_event_unit_detail4.event_seq
        AND pevent4.event_agency = pln_event_unit_detail4.event_agency
        AND pevent4.event_owner = pln_event_unit_detail4.event_owner
        AND pevent4.event_code = pln_event_unit_detail4.event_code)            
    
    WHERE 
    SUBSTR(pevent4.event_code,1,5) IN ('OP270', 'PC270')
    AND (handler_id, unit_seq) IN 
    (SELECT DISTINCT 
      handler_id, 
      unit_seq
      
      FROM 
      (SELECT 
        handler_id,
        unit_seq,
        unit_detail_seq,
        effective_date,
        legal_operating_status
        
        FROM 
        punit_detail4
        
        WHERE
        current_unit_detail = 'Y'     
      )
      WHERE 
      SUBSTR(legal_operating_status,1,2) IN ('PI', 'PC', 'PM')
      AND SUBSTR(legal_operating_status,3,2) IN ('OP', 'IN', 'CP', 'DC', 'NE', 'CA', 'CN', 'UC', 'BC', 'AE')
    )
    
    GROUP BY 
    handler_id,
    CASE
    WHEN SUBSTR(pevent4.event_code,1,5) = 'OP270' THEN 'OPU'
    WHEN SUBSTR(pevent4.event_code,1,5) = 'PC270' THEN 'PCU'
    END
  )
  
  GROUP BY 
  handler_id                                    
  
  HAVING COUNT(*) > 1
) op_and_pc_permits                                     
ON hreport_univ5.handler_id = op_and_pc_permits.handler_id                  

-- $P!{c_exclude_not_state_workload_subquery}     
-- $P!{c_exclude_ca_permit_subquery}

LEFT JOIN 
(SELECT DISTINCT 
  pevent4.handler_id
  
  FROM 
  pevent4
  
  LEFT JOIN 
  (SELECT 
    handler_id, 
    MAX(actual_date) max_316ye
    
    FROM
    pevent4
    
    WHERE 
    event_owner = 'HQ'
    AND actual_date IS NOT NULL 
    AND event_code IN ('OP316YE', 'PC316YE') 
    
    GROUP BY 
    handler_id 
  ) op_pc316ye 
  ON pevent4.handler_id = op_pc316ye.handler_id
  
  WHERE 
  event_owner = 'HQ' 
  AND event_code IN ('OP316NO', 'PC316NO') 
  AND actual_date IS NOT NULL
  AND (op_pc316ye.max_316ye IS NULL 
       OR actual_date >= op_pc316ye.max_316ye)      
) state_workload_information 
ON hreport_univ5.handler_id = state_workload_information.handler_id

LEFT JOIN
(SELECT  
  handler_id, 
  MAX( TO_CHAR(actual_date, 'YYYYMMDD') || event_code) permit_info
  
  FROM
  
  pevent4
  
  WHERE  
  event_owner = 'HQ'  
  AND actual_date IS NOT NULL
  AND SUBSTR(event_code,1,5) IN ('OP200', 'PC200')                  
  GROUP BY 
  handler_id 
) permit_information 
ON hreport_univ5.handler_id = permit_information.handler_id 

JOIN rcrainfo.lu_state_view
ON hreport_univ5.state = lu_state_view.postal_code

WHERE 
SUBSTR(legal_operating_status,1,2) IN ('PI', 'PC', 'PM')
AND SUBSTR(legal_operating_status,3,2) IN ('OP', 'IN', 'CP', 'DC', 'NE', 'CA', 'CN', 'UC', 'BC', 'AE') 
        -- hreport_univ5.region = '1'
        --AND permit_expiration_fy = fiscal_year_var

ORDER BY
hreport_univ5.region,
state_name,
handler_name,
hreport_univ5.handler_id,
punit4.unit_seq")