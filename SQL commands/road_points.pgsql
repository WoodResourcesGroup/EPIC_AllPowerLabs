-- New version 3 of the distance calculation query. For this query the <-> has been 
-- eliminated, considering that the distance is already calculated then is more effective 
-- to use it in the ORDER BY statement. 

DROP TABLE IF EXISTS lemmav2.lemma_landingpoints;
CREATE TABLE lemmav2.lemma_landingpoints
(kmeans_cluster_number integer, pol_id integer, count integer, biomass_total double precision, 
weighted_center_geom geometry, road_id integer, distance double precision,
road_geom geometry, landingpoint_geom geometry);

DO $$ 
declare 
	pid lemmav2.lemma_clusterquantity.pol_id%TYPE;
BEGIN
  FOR pid IN 
<<<<<<< HEAD
  select pol_id as pid from lemmav2.lemma_clusterquantity where cluster_quantity < 64 order by cluster_quantity desc limit 95
=======
  select pol_id as pid from lemmav2.lemma_clusterquantity where cluster_quantity < 99 order by cluster_quantity desc limit 103
>>>>>>> 99eb36c2b15478b3dfdc47899d0f9e84061b90f5
  LOOP 
    RAISE NOTICE 'Analyzing_polygon %', pid;
    INSERT INTO lemmav2.lemma_landingpoints
    SELECT DISTINCT ON(kmeans_cluster_number) lemma_clusterscenter.kmeans_cluster_number as kmeans_cluster_number, lemma_clusterscenter.pol_id as pol_id, 
		lemma_clusterscenter.count as count, lemma_clusterscenter.biomass_total as biomass_total, lemma_clusterscenter.weighted_center_geom AS weighted_center_geom, 
		roads_data.id AS road_id, 
		-- Distance calculation
		ST_Distance(st_transform(lemma_clusterscenter.weighted_center_geom,5070),st_transform(roads_data.wkb_geometry,5070)) AS distance, 
		roads_data.wkb_geometry AS road_geom
	FROM lemmav2.lemma_clusterscenter, roads_data.roads_california As roads_data
	WHERE ST_DWithin(st_transform(lemma_clusterscenter.weighted_center_geom,5070), st_transform(roads_data.wkb_geometry,5070), 1600) 
				and lemmav2.lemma_clusterscenter.count > 50 
				and lemmav2.lemma_clusterscenter.biomass_total > 25000
				and lemma_clusterscenter.pol_id = pid
	ORDER BY kmeans_cluster_number, pol_id, distance; 

UPDATE lemmav2.lemma_landingpoints SET landingpoint_geom = ref.point
FROM (SELECT kmeans_cluster_number, pol_id, ST_LineInterpolatePoint(ST_transform(road_geom,5070),ST_LineLocatePoint(ST_transform(road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
FROM lemmav2.lemma_landingpoints WHERE lemmav2.lemma_landingpoints.pol_id = pid) AS ref
WHERE lemmav2.lemma_landingpoints.pol_id = ref.pol_id and lemmav2.lemma_landingpoints.kmeans_cluster_number = ref.kmeans_cluster_number;

	  END LOOP;
  RETURN;
END; $$;

-- Query to calculate the actual point in the road. 

UPDATE lemmav2.lemma_landingpoints SET landingpoint_geom = ref.point
FROM (SELECT kmeans_cluster_number, pol_id, ST_LineInterpolatePoint(ST_transform(road_geom,5070),ST_LineLocatePoint(ST_transform(road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
FROM lemmav2.lemma_landingpoints) AS ref
WHERE lemmav2.lemma_landingpoints.pol_id = ref.pol_id and lemmav2.lemma_landingpoints.kmeans_cluster_number = ref.kmeans_cluster_number;