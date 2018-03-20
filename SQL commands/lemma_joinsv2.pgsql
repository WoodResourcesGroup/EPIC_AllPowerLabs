-- Get the sum of dead biomass 
set search_path  = lemmav2, public;
drop table lemma_totalv2;
create table lemma_totalv2 as
select x, y, array_agg(key order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as key_h, array_agg("RPT_YR" order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as year, 
  array_agg("Pol.ID" order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as pol_id_h, 
  array_agg("trunc25CRM" order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as trunc25crm_h,
  array_agg("trunc3CRM" order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as trunc3crm_h,
  array_agg("trunc25J" order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as trunc25J_h,
  array_agg("trunc3J" order by "RPT_YR" desc, "Pol.Shap_Ar" desc) as trunc3J_h,
  max("TPH_GE_25")/2.47105 as live_trees_acre_25, max("relNO25")/0.222395 as dead_trees_acre25, 
  max("TPH_GE_3")/2.47105 as live_trees_acre_3, max("relNO3")/0.222395 as dead_trees_acre3, 
  max("bm_liveCRM_25_kg") as bm_liveCRM_25_kg, max("bm_liveCRM_3_kg") as bm_liveCRM_3_kg, max("bm_liveJ_25_kg") as bm_liveJ_25_kg, max("bm_liveJ_3_kg") as bm_liveJ_3_kg, 
  -- Volumes per tree    
  max("VPT") as vpt_25,
  -- Biomass Estimates
  sum("D_BM_kg25CRM")*(sum("D_BM_kg25CRM") <= max("bm_liveCRM_25_kg"))::INT + max("D_BM_kg25CRM")*(1-(sum("D_BM_kg25CRM") <= max("bm_liveCRM_25_kg"))::INT) as "D_BM_kgsum_25CRM", 
  sum("D_BM_kg3CRM")*(sum("D_BM_kg3CRM") <= max("bm_liveCRM_3_kg"))::INT + max("D_BM_kg3CRM")*(1-(sum("D_BM_kg3CRM") <= max("bm_liveCRM_3_kg"))::INT) as "D_BM_kgsum_3CRM", 
  sum("D_BM_kg25J")*(sum("D_BM_kg25J") <= max("bm_liveJ_25_kg"))::INT + max("D_BM_kg25J")*(1-(sum("D_BM_kg25J") <= max("bm_liveJ_25_kg"))::INT) as "D_BMkg_sum25J", 
  sum("D_BM_kg3J")*(sum("D_BM_kg3J") <= max("bm_liveJ_3_kg"))::INT + max("D_BM_kg3J")*(1-(sum("D_BM_kg3J") <= max("bm_liveJ_3_kg"))::INT) as "D_BMkg_sum3J",  
  -- Recording of the max
  max("D_BM_kg25CRM") as "D_BM_kg25CRM_max", max("D_BM_kg3CRM") as "D_BM_kg3CRM_max", max("D_BM_kg25J") as "D_BM_kg25J_max", max("D_BM_kg3J") as "D_BM_kg3J_max",
  -- Truncation
  sum("D_BM_kg25CRM") >= max("bm_liveCRM_25_kg") as truncation25CRM,  
  sum("D_BM_kg3CRM") >= max("bm_liveCRM_3_kg") as truncation3CRM, 
  sum("D_BM_kg25J") >= max("bm_liveJ_25_kg") as truncation25j,  
  sum("D_BM_kg3J") >= max("bm_liveJ_3_kg") as truncation3j,  
  -- Logic CHECK
  sum("D_BM_kg25CRM")*(sum("D_BM_kg25CRM") <= max("bm_liveCRM_25_kg"))::INT + max("D_BM_kg25CRM")*(1-(sum("D_BM_kg25CRM") <= max("bm_liveCRM_25_kg"))::INT) > max("bm_liveCRM_25_kg") as check25CRM,
  sum("D_BM_kg3CRM")*(sum("D_BM_kg3CRM") <= max("bm_liveCRM_3_kg"))::INT + max("D_BM_kg3CRM")*(1-(sum("D_BM_kg3CRM") <= max("bm_liveCRM_3_kg"))::INT) > max("bm_liveCRM_3_kg") as check3CRM,
  sum("D_BM_kg25J")*(sum("D_BM_kg25J") <= max("bm_liveJ_25_kg"))::INT + max("D_BM_kg25J")*(1-(sum("D_BM_kg25J") <= max("bm_liveJ_25_kg"))::INT) > max("bm_liveJ_25_kg") as check25j,
  sum("D_BM_kg3J")*(sum("D_BM_kg3J") <= max("bm_liveJ_3_kg"))::INT + max("D_BM_kg3J")*(1-(sum("D_BM_kg3J") <= max("bm_liveJ_3_kg"))::INT) > max("bm_liveJ_3_kg") as check3j, 
count(*)
from (select * from lemma1215v2 union select * from lemma2016v2 union select * from lemma2017v2) as foo
group by x, y having count(*) > 1
order by count(*) desc limit 5; -- 6 511 279

alter table lemma_totalv2 add column pol_id int;
alter table lemma_totalv2 add column key int;
update lemma_totalv2 set pol_id = pol_id_h[1];
update lemma_totalv2 set key = key_h[1];
alter table lemma_totalv2 add primary key (key, pol_id);
alter table lemma_totalv2 drop column if exists geom;
SELECT AddGeometryColumn ('lemmav2','lemma_totalv2','geom',5070,'POINT',2);
UPDATE lemma_totalv2 set geom = ST_SetSRID(st_makepoint(x, y), 5070)::geometry;


INSERT INTO lemma_total (
select x, y, array_agg(key order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as key_h, array_agg("RPT_YR" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as year, 
  array_agg("Pol.ID" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as pol_id_h, 
  array_agg("Pol.Shap_Ar" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as polygon_area_h,
  max("TPH_GE_25")/2.47105 as live_trees_acre_lemma, max("relNO")/0.222395 as dead_trees_acre, 
  max("BPH_abs") as total_bm_2012, max("VPT") as vpt, 
  sum("D_BM_kg")*(sum("D_BM_kg") <= max("BPH_abs"))::INT + max("D_BM_kg")*(1-(sum("D_BM_kg") <= max("BPH_abs"))::INT) as "D_BM_kg_sum", 
  max("D_BM_kg") as "D_BM_kg_max", 
  (sum("D_BM_kg")*(sum("D_BM_kg") <= max("BPH_abs"))::INT + max("D_BM_kg")*(1-(sum("D_BM_kg") <= max("BPH_abs"))::INT)) > max("BPH_abs") as truncation,
count(*)
from (select * from lemma_1215 union select * from lemma_2016) as foo
group by x, y
having count(*) = 1
order by count(*) desc); -- 21 549 683
-- remove pixels with 0 biomass. This justifies better the spatial filtering from k-means 
delete from lemma_totalv2 where "D_BM_kg_sum" = 0;

  --- Original Query working

set search_path  = lemmav2, public; 
select x, y, array_agg("RPT_YR") as year, max("BPH_abs") as total_bm_2012, array_agg(trunc) trunc_hist, sum("D_BM_kg") as "D_BM_kg", sum("D_BM_kg") > max("BPH_abs") as truncation,
count(*)
from (select * from lemma_1215 union select * from lemma_2016) as foo where trunc != 1 
group by x, y
having count(*) > 1
order by count(*) desc 

-- check query for the number of independent pixels
set search_path  = lemmav2, public; 
select x, y, count(*)
from lemma_total 
group by x, y
having count(*) > 1
order by count(*) desc 
