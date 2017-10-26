-- Calculate the biomass amounts that can be harvested A

set search_path = lemmav2, general_gis_data, public;



alter table raw_totals_county add column total_cluster_200 NUMERIC;
UPDATE lemmav2.raw_totals_county SET total_cluster_200 = temp.totals 
from (select sum("D_BM_kg_sum") as totals, counties group by counties) as temp where raw_totals_county.county = counties;
