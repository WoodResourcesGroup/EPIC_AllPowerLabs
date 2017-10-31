
-- Fill in the gaps between the tables
INSERT INTO lemma_slope
select lemma_total.geom, lemma_total.x, lemma_total.y, lemma_total.pol_id, lemma_total.key, lemma_slope.slope, lemma_slope.slope_group from lemma_total left join lemma_slope using(key, pol_id) where slope is NULL

-- create the categories
alter table lemma_slope add column slope_group INT;
UPDATE lemmav2.lemma_slope SET slope_group = ceil(slope/5)


-- make the cum_sum for each of the clustering values 

DROP TABLE IF EXISTS lemma_cumsum_slope;
CREATE TABLE lemmav2.lemma_cumsum_slope AS
select f.slope_group*5, sum(f.biomass_sum) over(order by f.slope_group) as cum_sum from (
select lemma_slope.slope_group , sum(lemma_dbscanclusters220.d_bm_kg/1000000) as biomass_sum  from lemma_dbscanclusters220 inner join lemma_slope using(key, pol_id) group by lemma_slope.slope_group) as f 
order by f.slope_group;

alter table lemma_dbscancenters180 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters180 add column sum_distances_sq NUMERIC;


-- cum sum by VPT. 

DROP TABLE IF EXISTS lemma_cumsum_vpt;
CREATE TABLE lemmav2.lemma_cumsum_vpt AS
select f.vpt_category*10, sum(f.biomass_sum) over(order by f.vpt_category) as cum_sum from (
select ceil(VPT*35.3147/10) as vpt_category, sum(lemma_dbscanclusters220.d_bm_kg/1000000) as biomass_sum  from lemma_dbscanclusters220 inner join lemma_total using(key, pol_id) where vpt < 11.32 group by vpt_category) as f
order by f.vpt_category;

