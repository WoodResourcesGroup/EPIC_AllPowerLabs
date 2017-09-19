-- Calculate the biomass amounts that can be harvested A

set search_path = lemmav2, general_gis_data, public;
create table total_counties as (SELECT lemma_total.*, counties.county from lemma_total, "California_counties" as counties
	where st_within(lemma_total.geom, st_transform(counties.the_geom,5070)));