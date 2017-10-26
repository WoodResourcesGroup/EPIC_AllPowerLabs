-- obtain a portion of the data 
set search_path = lemmav2, general_gis_data, public;
SELECT key, pol_id, county from "California_counties", lemma_total
	where st_within(lemma_total.geom, st_transform("California_counties".the_geom,5070)) limit 10; 

alter table lemmav2.lemma_total drop column if county;
alter table lemmav2.lemma_total add column county text;
UPDATE lemmav2.lemma_total SET county = temp.county 
from (SELECT key, pol_id, "California_counties".county from "California_counties", lemma_total
	where st_within(lemma_total.geom, st_transform("California_counties".the_geom,5070))) as temp where lemmav2.lemma_total.key = temp.key and lemmav2.lemma_total.pol_id = temp.pol_id; 


UPDATE lemmav2.lemma_total SET county = temp.county 
from (SELECT key, pol_id, "California_counties".county from "California_counties", lemma_total where lemma_total.county is NULL order by lemma_total.geom <-> st_transform("California_counties".the_geom,5070)) as temp where lemmav2.lemma_total.key = temp.key and lemmav2.lemma_total.pol_id = temp.pol_id; 
	set search_path = lemmav2, general_gis_data, public;
