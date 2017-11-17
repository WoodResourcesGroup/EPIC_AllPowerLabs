
-- Case of chinese station
create table case_chinese_station as 
select *, ST_distance(st_transform(ST_SetSRID(ST_MakePoint(-120.475927, 37.844249),4326),5070), lemma_dbscanclusters220.geom) as distance from lemma_dbscanclusters220
where ST_DWithin(st_transform(ST_SetSRID(ST_MakePoint(-120.475927, 37.844249),4326),5070), lemma_dbscanclusters220.geom, 100000);

ST_SetSRID(ST_MakePoint(-120.475927, 37.844249),4326)

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