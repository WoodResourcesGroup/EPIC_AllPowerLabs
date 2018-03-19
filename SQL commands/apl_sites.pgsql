
-- Case of chinese station
drop table case_chinese_station;
create table case_chinese_station as 
select  f.*, ST_distance(st_transform(ST_SetSRID(ST_MakePoint(-120.475927, 37.844249),4326),5070), f.geom) as linear_distance 
from (select t.*, lemma_slope.slope_group, lemma_slope.slope from (select lemma_total.vpt, lemma_dbscanclusters220.* from lemma_dbscanclusters220 
inner join lemma_total using(key, pol_id) where vpt < 11.32 and wilderness_area is null and county is not null) as t inner join lemma_slope using(key, pol_id) ) as f 
where ST_DWithin(st_transform(ST_SetSRID(ST_MakePoint(-120.475927, 37.844249),4326),5070), f.geom, 100000);

select ceil(VPT) as vpt_category, sum(case_chinese_station.biomass*1.102/1000000) as biomass_sum  from case_chinese_station inner join lemma_total using(key, pol_id) where vpt < 13 and linear_distance < 30000 group by vpt_category

-- Case of rio bravo station
drop table case_rio_bravo;
create table case_rio_bravo as 
select *, ST_distance(st_transform(ST_SetSRID(ST_MakePoint(-119.723942, 36.687512),4326),5070), lemma_kmeansclustering.geom) as linear_distance from lemma_kmeansclustering
where ST_DWithin(st_transform(ST_SetSRID(ST_MakePoint(-119.723942, 36.687512),4326),5070), lemma_kmeansclustering.geom, 100000);

------------------------------------------------------------------------------------------------
create table case_studies (name string, geom geom(5070), total_biomas double PRECISION);

-- Biosum inside areas 

drop table sandbox.biosum_sites;
CREATE TABLE sandbox.biosum_sites AS
  SELECT biosum.latlon.*, sandbox.apl_sites.name FROM biosum.latlon, sandbox.apl_sites WHERE ST_DWithin(st_transform(sandbox.apl_sites.geom_p,5070), st_transform(biosum.latlon.geom,5070), 46000);
  
-- Get biomass data from scenarios 
-- Adjust for every scenario number, some scenarios have 0 yield. 

alter table sandbox.biosum_sites add yield_scenario3 double precision; 
update sandbox.biosum_sites
set yield_scenario3 = biosum.biomass_case3.yield_gt
from biosum.biomass_case3 where sandbox.biosum_sites.biosum_cond_id = biosum.biomass_case3.biosum_cond_id;

-- Total calculation 

alter table sandbox.apl_sites add yield_scenario3 double precision; 
update sandbox.apl_sites
set yield_scenario3 = (select sum(sandbox.biosum_sites.yield_scenario3)
from sandbox.biosum_sites where sandbox.apl_sites.name = sandbox.biosum_sites.name);

-- Lemma 

drop table if exists sandbox.lemma_sites;
CREATE TABLE sandbox.lemma_sites AS 
  SELECT lemma.lemma_crmort.*, sandbox.apl_sites. FROM lemma.lemma_crmort, sandbox.apl_sites WHERE ST_DWithin(st_transform(sandbox.apl_sites.geom_p,5070), st_transform(lemma.lemma_crmort.geom,5070), 46000);
  
-- Totals calculation LEMMA 

alter table sandbox.apl_sites add yield_lemma double precision; 
update sandbox.apl_sites
set yield_lemma = (select sum(sandbox.lemma_sites."D_CONBM_kg")
from sandbox.lemma_sites where sandbox.apl_sites.name = sandbox.lemma_sites.name);    