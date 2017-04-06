-- New version 3 of the distance calculation query. For this query the <-> has been 
-- eliminated, considering that the distance is already calculated then is more effective 
-- to use it in the ORDER BY statement. 

DROP TABLE IF EXISTS lemma.geometries_result_pav2;
CREATE TABLE lemma.geometries_result_pav2
(kmeans_id integer, pol_id integer, kmeans_count integer, biomass double precision, 
weighted_center_geom geometry, weighted_road_id integer, weighted_distance double precision,
weighted_road_geom geometry, point_on_road geometry);

DO $$ 
declare 
	pid lemma.polygon_priority_areas.id%TYPE;
BEGIN
  FOR pid IN 
  select id as pid from lemma.polygon_priority_areas
  LOOP 
    RAISE NOTICE 'Analyzing_polygon %', pid;
    INSERT INTO lemma.geometries_result_pav2
    SELECT DISTINCT ON(kmeans_id) g1.kmeans AS kmeans_id, pol_id, g1.count AS kmeans_count, g1.biomass AS biomass, g1.weighted_center_geom AS weighted_center_geom, 
	g2.id AS weighted_road_id, ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
	g2.wkb_geometry AS weighted_road_geom
	FROM lemma.center_result_pa2 As g1, roads_data.roads_california As g2
	WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000) and g1.pol_id = pid
	ORDER BY kmeans_id, pol_id, kmeans_id, weighted_distance;  
	
	UPDATE lemma.geometries_result_pav2
	SET point_on_road = ref.point
	FROM 
	(SELECT kmeans_id, pol_id, ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),ST_LineLocatePoint(ST_transform(weighted_road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
	FROM lemma.geometries_result_pav2 WHERE lemma.geometries_result_pav2.pol_id = pid) AS ref
	WHERE lemma.geometries_result_pav2.pol_id = ref.pol_id and lemma.geometries_result_pav2.kmeans_id = ref.kmeans_id;
	  
  END LOOP;
  RETURN;
END; $$;