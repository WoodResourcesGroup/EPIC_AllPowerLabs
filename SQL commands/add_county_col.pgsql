-- obtain a portion of the data 
set search_path = lemmav2, general_gis_data, public;
SELECT key, pol_id, county from "California_counties", lemma_total
	where st_within(lemma_total.geom, st_transform("California_counties".the_geom,5070)) limit 10; 

alter table lemmav2.lemma_total drop column if exists county;
alter table lemmav2.lemma_total add column county text;
UPDATE lemmav2.lemma_total SET county = temp.county 
from (SELECT key, pol_id, "California_counties".county from "California_counties", lemma_total
	where st_within(lemma_total.geom, st_transform("California_counties".the_geom,5070))) as temp where lemmav2.lemma_total.key = temp.key and lemmav2.lemma_total.pol_id = temp.pol_id; 


UPDATE lemmav2.lemma_dbscancluster220 SET cluster_no = temp.county, kmeans_cluster_no 
from (SELECT key, pol_id, "California_counties".county from "California_counties", lemma_total where lemma_total.county is NULL order by lemma_total.geom <-> st_transform("California_counties".the_geom,5070)) as temp where lemmav2.lemma_total.key = temp.key and lemmav2.lemma_total.pol_id = temp.pol_id; 
	set search_path = lemmav2, general_gis_data, public;

UPDATE frcs_cost_test SET "All Costs, $/GT" = 250 where "All Costs, $/GT" > 500 ;   


SELECT key, pol_id, "California_counties".county from "California_counties", lemma_total where lemma_total.county is NULL order by lemma_total.geom <-> st_transform("California_counties".the_geom,5070)


select temp1.cluster_no, lemma_dbscanclusters220.cluster_no, kmeans_cluster_no from lemma_dbscanclusters220, 
(select key, pol_id, lemma_dbscanclusters220.cluster_no, geom from lemma_dbscanclusters220, (select cluster_no from lemma_dbscancenters220 where kmeans_cluster_quantity < 1 limit 1) as t where lemma_dbscanclusters220.cluster_no = t.cluster_no) as temp1 
where temp1.cluster_no <> lemma_dbscanclusters220.cluster_no AND ST_DWithin(temp1.geom, lemma_dbscanclusters220.geom, 100) order by temp1.geom <-> lemma_dbscanclusters220.geom;



alter table lemmav2.lemma_kmeansclustering drop column if exists nps_area;
alter table lemmav2.lemma_kmeansclustering add column nps_area text;
UPDATE lemmav2.lemma_kmeansclustering SET nps_area = temp.nps_area 
from (SELECT key, pol_id, nps_boundary_california.unit_name as nps_area from nps_boundary_california, lemma_kmeansclustering
	where st_within(lemma_kmeansclustering.geom, nps_boundary_california.geom) )as temp where lemmav2.lemma_kmeansclustering.key = temp.key and lemmav2.lemma_kmeansclustering.pol_id = temp.pol_id; 

alter table lemmav2.lemma_kmeansclustering drop column if exists wilderness_area;
alter table lemmav2.lemma_kmeansclustering add column wilderness_area text;
UPDATE lemmav2.lemma_kmeansclustering SET wilderness_area = temp.wilderness_area 
from (SELECT key, pol_id, wilderness_areas_california.name as wilderness_area from wilderness_areas_california, lemma_kmeansclustering
	where st_within(lemma_kmeansclustering.geom, wilderness_areas_california.geom) )as temp where lemmav2.lemma_kmeansclustering.key = temp.key and lemmav2.lemma_kmeansclustering.pol_id = temp.pol_id; 

alter table lemmav2.lemma_total drop column if exists wilderness_area;
alter table lemmav2.lemma_total add column wilderness_area text;
UPDATE lemmav2.lemma_total SET wilderness_area = temp.wilderness_area 
from (SELECT key, pol_id, wilderness_areas_california.name as wilderness_area from wilderness_areas_california, lemma_total
	where st_within(lemma_total.geom, wilderness_areas_california.geom) )as temp where lemmav2.lemma_total.key = temp.key and lemmav2.lemma_total.pol_id = temp.pol_id; 
