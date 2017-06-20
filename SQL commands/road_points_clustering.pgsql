-- First test without including the new geom for the cluster of landing locations. 
Drop table lemmav2.lemma_landingclusters;
CREATE TABLE lemmav2.lemma_landingclusters
(road_id integer, pol_id integer, kmeans_cluster_number integer, road_cluster integer, landingpoint_geom geometry);
alter table lemmav2.lemma_landingclusters add primary key (road_id, road_cluster);


a 



-- Scratch pad


    SELECT pol_id, kmeans_cluster_number, landingpoint_geom
	FROM lemmav2.lemma_landingpoints, roads_data.roads_california As roads_data
	WHERE ST_DWithin(st_transform(lemma_clusterscenter.weighted_center_geom,5070), st_transform(roads_data.wkb_geometry,5070), 1600) 
				and lemmav2.lemma_clusterscenter.count > 50 
				and lemmav2.lemma_clusterscenter.biomass_total > 25000
				and lemma_clusterscenter.pol_id = pid
	ORDER BY kmeans_cluster_number, pol_id, distance; 

SELECT row_number() over () AS id,
  ST_NumGeometries(gc),
  gc AS geom_collection,
  ST_Centroid(gc) AS centroid,
  ST_MinimumBoundingCircle(gc) AS circle,
  sqrt(ST_Area(ST_MinimumBoundingCircle(gc)) / pi()) AS radius
FROM (
  SELECT unnest(ST_ClusterWithin(geom, 100)) gc
  FROM rand_point
) f;

select row_number() over () as id, ST_ClusterWithin(landingpoint_geom, 100) as gc from lemmav2.lemma_landingpoints group by road_id;

select road_id, count(*) as count, ST_collect(landingpoint_geom) as gc from lemmav2.lemma_landingpoints_temp group by road_id order by count desc limit 3;