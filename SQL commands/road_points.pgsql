-- Query to calculate the pixel's distance. 

update roads_california_filtered set geom = st_transform(wkb_geometry,5070);

-- These queries run so much faster because they don't do conversions anymore. 

UPDATE lemma_kmeanscenters SET landing_point = temp.landing_loc, distance_to_landing_point = temp.distance from
(SELECT
  lemma_kmeanscenters.*,
  landing_points.ogc_fid as landing_id,
  landing_points.point_geom as landing_loc,
  ST_Distance(lemma_kmeanscenters.weighted_center_geom,landing_points.point_geom) AS distance
FROM
  lemma_kmeanscenters
CROSS JOIN LATERAL
  (SELECT ogc_fid, geom as geom, 
  ST_LineInterpolatePoint(geom, ST_LineLocatePoint(geom, lemma_kmeanscenters.weighted_center_geom)) AS point_geom
   FROM roads_data.roads_california_filtered
   ORDER BY
     lemma_kmeanscenters.weighted_center_geom <-> geom
   LIMIT 1) AS landing_points) as temp where lemma_kmeanscenters.cluster_no = temp.cluster_no and lemma_kmeanscenters.kmeans_cluster_no = temp.kmeans_cluster_no; 


-- New version to be use with the cleaner data, get the road id to the kmeans cluster 

UPDATE lemma_kmeanscenters SET landing_road = temp.landing_id, distance_to_landing_road = temp.distance from
(SELECT
  lemma_kmeanscenters.*,
  landing_points.ogc_fid as landing_id,
  ST_Distance(lemma_kmeanscenters.weighted_center_geom,landing_points.geom) AS distance
FROM
  lemma_kmeanscenters
CROSS JOIN LATERAL
  (SELECT ogc_fid, geom as geom
   FROM roads_data.roads_california_filtered
   ORDER BY
     lemma_kmeanscenters.weighted_center_geom <-> geom
   LIMIT 1) AS landing_points) as temp where lemma_kmeanscenters.cluster_no = temp.cluster_no and lemma_kmeanscenters.kmeans_cluster_no = temp.kmeans_cluster_no; 

-- Query to add the correction for slope in the AYD

update lemma_slope set ayd_corr_factor = sqrt(1+(slope/100)^2);


-- New version 3 of the distance calculation query. For this query the <-> has been 
-- eliminated, considering that the distance is already calculated then is more effective 
-- to use it in the ORDER BY statement. 

DROP TABLE IF EXISTS lemmav2.lemma_landingpoints3;
CREATE TABLE lemmav2.lemma_landingpoints3
(kmeans_cluster_number integer, pol_id integer, count integer, biomass_total double precision, 
weighted_center_geom geometry, road_id integer, distance double precision,
road_geom geometry, landingpoint_geom geometry);

DO $$ 
declare 
	pid lemmav2.lemma_clusterquantity.pol_id%TYPE;
BEGIN
  FOR pid IN 
  select pol_id as pid from lemmav2.lemma_clusterquantity where cluster_quantity >= 1  order by cluster_quantity desc
  LOOP 
    RAISE NOTICE 'Analyzing_polygon %', pid;
    INSERT INTO lemmav2.lemma_landingpoints3
    SELECT DISTINCT ON(kmeans_cluster_number) lemma_clusterscenter.kmeans_cluster_number as kmeans_cluster_number, lemma_clusterscenter.pol_id as pol_id, 
		lemma_clusterscenter.count as count, lemma_clusterscenter.biomass_total as biomass_total, lemma_clusterscenter.weighted_center_geom AS weighted_center_geom, 
		roads_data.id AS road_id, 
		-- Distance calculation
		ST_Distance(st_transform(lemma_clusterscenter.weighted_center_geom,5070),st_transform(roads_data.wkb_geometry,5070)) AS distance, 
		roads_data.wkb_geometry AS road_geom
	FROM lemmav2.lemma_clusterscenter, (select * from roads_data.roads_california where highway is not null) As roads_data
	WHERE ST_DWithin(st_transform(lemma_clusterscenter.weighted_center_geom,5070), st_transform(roads_data.wkb_geometry,5070), 1600) 
				and lemmav2.lemma_clusterscenter.count > 50 
				and lemmav2.lemma_clusterscenter.biomass_total > 25000
				and lemma_clusterscenter.pol_id = pid
	ORDER BY kmeans_cluster_number, pol_id, distance; 

UPDATE lemmav2.lemma_landingpoints3 SET landingpoint_geom = ref.point
FROM (SELECT kmeans_cluster_number, pol_id, ST_LineInterpolatePoint(ST_transform(road_geom,5070),ST_LineLocatePoint(ST_transform(road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
FROM lemmav2.lemma_landingpoints3 WHERE lemmav2.lemma_landingpoints3.pol_id = pid) AS ref
WHERE lemmav2.lemma_landingpoints3.pol_id = ref.pol_id and lemmav2.lemma_landingpoints3.kmeans_cluster_number = ref.kmeans_cluster_number;

	  END LOOP;
  RETURN;
END; $$;

-- Query to calculate the actual point in the road. 

UPDATE lemmav2.lemma_landingpoints SET landingpoint_geom = ref.point
FROM (SELECT kmeans_cluster_number, pol_id, 
ST_LineInterpolatePoint(ST_transform(road_geom,5070),
ST_LineLocatePoint(ST_transform(road_geom,5070), 
ST_transform(weighted_center_geom,5070))) AS point
FROM lemmav2.lemma_landingpoints) AS ref
WHERE lemmav2.lemma_landingpoints.pol_id = ref.pol_id and lemmav2.lemma_landingpoints.kmeans_cluster_number = ref.kmeans_cluster_number;

delete from lemma_landingpoints_temp where road_id in (select id from roads_california where highway is null);