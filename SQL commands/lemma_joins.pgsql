-- Get the sum of dead biomass 
set search_path  = lemmav2, public;
drop table lemma_total;
create table lemma_total as
select x, y, array_agg(key order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as key_h, array_agg("RPT_YR" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as year, 
  array_agg("Pol.ID" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as pol_id_h, 
  array_agg("Pol.Shap_Ar" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as polygon_area_h,
  max("TPH_GE_25")/2.47105 as live_trees_acre_lemma, max("relNO")/0.222395 as dead_trees_acre, 
  max("BPH_abs") as total_bm_2012, max("VPT") as vpt, 
  sum("D_BM_kg")*(sum("D_BM_kg") <= max("BPH_abs"))::INT + max("D_BM_kg")*(1-(sum("D_BM_kg") <= max("BPH_abs"))::INT) as "D_BM_kg_sum", 
  max("D_BM_kg") as "D_BM_kg_max", 
  (sum("D_BM_kg")*(sum("D_BM_kg") <= max("BPH_abs"))::INT + max("D_BM_kg")*(1-(sum("D_BM_kg") <= max("BPH_abs"))::INT)) > max("BPH_abs") as truncation,
count(*), geom
from (select * from lemma_1215 union select * from lemma_2016) as foo
group by x, y, geom
having count(*) > 1
order by count(*) desc; -- 6 511 279

INSERT INTO lemma_total (
select x, y, array_agg(key order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as key_h, array_agg("RPT_YR" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as year, 
  array_agg("Pol.ID" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as pol_id_h, 
  array_agg("Pol.Shap_Ar" order by "Pol.Shap_Ar" desc, "RPT_YR" desc) as polygon_area_h,
  max("TPH_GE_25")/2.47105 as live_trees_acre_lemma, max("relNO")/0.222395 as dead_trees_acre, 
  max("BPH_abs") as total_bm_2012, max("VPT") as vpt, 
  sum("D_BM_kg")*(sum("D_BM_kg") <= max("BPH_abs"))::INT + max("D_BM_kg")*(1-(sum("D_BM_kg") <= max("BPH_abs"))::INT) as "D_BM_kg_sum", 
  max("D_BM_kg") as "D_BM_kg_max", 
  (sum("D_BM_kg")*(sum("D_BM_kg") <= max("BPH_abs"))::INT + max("D_BM_kg")*(1-(sum("D_BM_kg") <= max("BPH_abs"))::INT)) > max("BPH_abs") as truncation,
count(*), geom
from (select * from lemma_1215 union select * from lemma_2016) as foo
group by x, y, geom
having count(*) = 1
order by count(*) desc); -- 21 549 683

alter table lemma_total add column pol_id int;
alter table lemma_total add column key int;
update lemma_total set pol_id = pol_id_h[1];
update lemma_total set key = key_h[1];
alter table lemma_total add primary key (key, pol_id);

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