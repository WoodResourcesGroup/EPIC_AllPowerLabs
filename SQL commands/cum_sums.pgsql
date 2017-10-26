
-- Fill in the gaps between the tables
INSERT INTO lemma_slope
select lemma_total.geom, lemma_total.x, lemma_total.y, lemma_total.pol_id, lemma_total.key, lemma_slope.slope, lemma_slope.slope_group from lemma_total left join lemma_slope using(key, pol_id) where slope is NULL

-- create the categories
alter table lemma_slope add column slope_group INT;
UPDATE lemmav2.lemma_slope SET slope_group = ceil(slope/5)


select lemma_slope.slope_group, sum(lemma_dbscanclusters220.d_bm_kg/1000000) as biomass_sum  from lemma_dbscanclusters220 inner join lemma_slope using(key, pol_id) group by lemma_slope.slope_group;

