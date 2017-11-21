-- Calculate the biomass amounts that can be harvested A

set search_path = lemmav2, general_gis_data, public;
drop table if exists raw_totals_county;
create table raw_totals_county as 
select sum("D_BM_kg_sum") as totals_raw, county from lemma_total group by county order by totals_raw desc;
alter table raw_totals_county add column total_cluster_200 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_200 = temp.totals 
from (select sum(lemma_dbscanclusters220.d_bm_kg/1000000) as totals, lemma_total.county from lemma_dbscanclusters220 inner join lemma_total using(key, pol_id) group by county) as temp where raw_totals_county.county = temp.county;

select lemma_total.county, sum(lemma_dbscanclusters220.d_bm_kg)/(1000000)
from lemma_dbscanclusters220 inner join lemma_total using(key, pol_id) 
inner join lemma_slope using(key, pol_id) 
where lemma_total.vpt < 80/2.27 and lemma_slope.slope_group < 40 group by lemma_total.county;