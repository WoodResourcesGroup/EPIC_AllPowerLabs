-- Calculate the biomass amounts that can be harvested A

set search_path = lemmav2, general_gis_data, public;


alter table raw_totals_county add column total_cluster_180 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_180 = temp.totals 
from (select sum(lemma_dbscanclusters180.d_bm_kg)/(1000*1000) as totals, lemma_total.county as counties from lemma_dbscanclusters180 inner join lemma_total using(key, pol_id) group by lemma_total.county order by totals desc) as temp where raw_totals_county.county = counties;

alter table raw_totals_county add column total_cluster_190 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_190 = temp.totals 
from (select sum(lemma_dbscanclusters190.d_bm_kg)/(1000*1000) as totals, lemma_total.county as counties from lemma_dbscanclusters190 inner join lemma_total using(key, pol_id) group by lemma_total.county order by totals desc) as temp where raw_totals_county.county = counties;

alter table raw_totals_county add column total_cluster_200 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_200 = temp.totals 
from (select sum(lemma_dbscanclusters200.d_bm_kg)/(1000*1000) as totals, lemma_total.county as counties from lemma_dbscanclusters200 inner join lemma_total using(key, pol_id) group by lemma_total.county order by totals desc) as temp where raw_totals_county.county = counties;

alter table raw_totals_county add column total_cluster_210 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_210 = temp.totals 
from (select sum(lemma_dbscanclusters210.d_bm_kg)/(1000*1000) as totals, lemma_total.county as counties from lemma_dbscanclusters200 inner join lemma_total using(key, pol_id) group by lemma_total.county order by totals desc) as temp where raw_totals_county.county = counties;

alter table raw_totals_county add column total_cluster_220 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_220 = temp.totals 
from (select sum(lemma_dbscanclusters220.d_bm_kg)/(1000*1000) as totals, lemma_total.county as counties from lemma_dbscanclusters220 inner join lemma_total using(key, pol_id) group by lemma_total.county order by totals desc) as temp where raw_totals_county.county = counties;


-- Calculate the tables for running sums given slope

INSERT INTO lemma_slope
select lemma_total.geom, lemma_total.x, lemma_total.y, lemma_total.pol_id, lemma_total.key, lemma_slope.slope, lemma_slope.slope_group from lemma_total left join lemma_slope using(key, pol_id) where slope is NULL

select lemma_slope.slope_group, sum(lemma_dbscanclusters220.d_bm_kg/1000000) as biomass_sum  from lemma_dbscanclusters220 inner join lemma_slope using(key, pol_id) group by lemma_slope.slope_group;

select lemma_total.county, sum(lemma_dbscanclusters220.d_bm_kg)/(1000000) as total 
from lemma_dbscanclusters220 inner join lemma_total using(key, pol_id) 
inner join lemma_slope using(key, pol_id) 
where lemma_total.vpt < 2.27 and lemma_slope.slope_group < 40 group by lemma_total.county order by total;