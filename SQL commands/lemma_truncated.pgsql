-- Calculate the biomass amounts that can be harvested A

set search_path = lemmav2, general_gis_data, public;
drop table if exists total_counties;
create table total_counties as (SELECT lemma_dbscanclusters200.*, counties.county from lemma_dbscanclusters200, "California_counties" as counties
	where st_within(lemma_dbscanclusters200.geom, st_transform(counties.the_geom,5070)));
alter table raw_totals_county add column total_cluster_200 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_200 = temp.totals 
from (select sum("D_BM_kg_sum") as totals, counties group by counties) as temp where raw_totals_county.county = counties;
