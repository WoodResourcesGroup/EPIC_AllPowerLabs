set search_path = biosum, public;
alter table latlon drop column if exists geom;
SELECT AddGeometryColumn ('biosum','latlon','geom',4326,'POINT',2);
UPDATE latlon set geom = ST_SetSRID(st_makepoint(latlon.lon, latlon.lat), 4326)::geometry;
create or replace view biosum.scenario1 as select s.*, l.geom  from "Scenario1" s join latlon l using (biosum_cond_id); 
create or replace view biosum.scenario2 as select s.*, l.geom  from "Scenario2" s join latlon l using (biosum_cond_id);
create or replace view biosum.scenario3 as select s.*, l.geom  from "Scenario3" s join latlon l using (biosum_cond_id);

set search_path = biosum, public;
create or replace view biomass_case1 as with cc as (select biosum_cond_id, count(*), sum(chip_yield_gt)/20 as ann20yield_gta, (sum(chip_yield_gt*acres))/20 as ann20yield_gt, case
	when sum(merch_val_dpa - (harvest_onsite_cpa+haul_merch_cpa)) <=0
	then 0
	else sum(merch_val_dpa-(harvest_onsite_cpa +haul_merch_cpa))
	end as chipcost_dpa from "Scenario1" where rxcycle in ('1','2') group by biosum_cond_id)
	select biosum_cond_id, chipcost_dpa/ann20yield_gta as cpa, l.geom from cc join latlon l using (biosum_cond_id) where ann20yield_gta >0 order by chipcost_dpa/ann20yield_gta asc;
	
with ca as (select st_union(geom) geom from "General_GIS_DATA"."California_counties") select * from roads_data.roads_california r, ca c where st_intersects(c.geom,r.geom)

set search_path = sandbox, public;
alter table sandbox."Trial_Biomass_Pixels_LEMMA_6" drop column if exists geom;
SELECT AddGeometryColumn ('sandbox','Trial_Biomass_Pixels_LEMMA_6','geom',5070,'POINT',2);
UPDATE "Trial_Biomass_Pixels_LEMMA_6" set geom = ST_SetSRID(st_makepoint("Trial_Biomass_Pixels_LEMMA_6".x, "Trial_Biomass_Pixels_LEMMA_6".y), 5070)::geometry;