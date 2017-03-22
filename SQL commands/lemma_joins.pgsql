-- Get the sum of dead biomass 
set search_path  = lemmav2, public;
drop table lemma_total;
create table lemma_total as
select x, y, key, "Pol.ID", "Pol.Shap_Ar", array_agg("RPT_YR") as year, max("QMD_DOM") as qmd_dom, 
  max("BPH_abs") as total_bm_2012, max("TPH_GE_25")/2.47105 as live_trees_acre, max("relNO")/0.222395 as dead_trees_acre, 
  sum("D_BM_kg") as "D_BM_kg", sum("D_BM_kg") > max("BPH_abs") as truncation, array_agg(trunc) trunc_hist,
count(*), geom
from (select * from lemma_1215 union select * from lemma_2016) as foo where trunc != 1
group by x, y, key, geom, "Pol.ID", "Pol.Shap_Ar"
order by count(*) desc;
INSERT INTO lemma_total (
  select x, y, key, "Pol.ID", "Pol.Shap_Ar", array_agg("RPT_YR") as year, max("QMD_DOM") as qmd_dom, 
    max("BPH_abs") as total_bm_2012, max("TPH_GE_25")/2.47105 as live_trees_acre, max("relNO")/0.222395 as dead_trees_acre, 
    max("D_BM_kg") as "D_BM_kg", sum("D_BM_kg") >= max("BPH_abs") as truncation, array_agg(trunc) trunc_hist,
  count(*), geom
  from (select * from lemma_1215 union select * from lemma_2016) as foo where trunc = 1
  group by x, y, key, geom, "Pol.ID", "Pol.Shap_Ar"
  order by count(*) desc);