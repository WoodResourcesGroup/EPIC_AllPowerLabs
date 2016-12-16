--Calculate the number of clusters in each polygon, the result is stored in sandbox.polygon
DROP TABLE IF EXISTS sandbox.polygon;
CREATE TABLE sandbox.polygon AS
SELECT DISTINCT id, CAST(CEILING(area / 350000) AS INTEGER) AS clusters
FROM
(SELECT DISTINCT "Pol.ID" AS id, "Pol.Shap_Ar" AS area 
FROM sandbox."Trial_Biomass_Pixels_LEMMA_6"
ORDER BY "Pol.ID") AS pol
ORDER BY id;


--Implement the kmeans on polygons, the result is stored in sandbox.kmeans_result_polygon

DROP TABLE IF EXISTS sandbox.kmeans_result_polygon;
CREATE TABLE sandbox.kmeans_result_polygon
(kmeans integer, pol_id integer, id integer, geom geometry, yield double precision);

DO $$ 
BEGIN
  FOR i IN 1..100 LOOP 
    INSERT INTO sandbox.kmeans_result_polygon
    SELECT kmeans(ARRAY[ST_X(geom), ST_Y(geom)], (SELECT clusters FROM sandbox.polygon WHERE id = i)) OVER (), "Pol.ID" as pol_id, key as pixel_id, geom, "D_CONBM_kg" as yield
    FROM sandbox."Trial_Biomass_Pixels_LEMMA_6"
    WHERE sandbox."Trial_Biomass_Pixels_LEMMA_6"."Pol.ID" = i 
    ORDER BY pol_id;
  END LOOP;
END; $$


DROP TABLE IF EXISTS lemma.kmeans_result_pa1;
CREATE TABLE lemma.kmeans_result_pa1
(kmeans integer, pol_id integer, id integer, geom geometry, yield double precision);

DO $$ 
declare 
	i lemma.polygon_priority_areas.id%TYPE;
BEGIN
  FOR i IN 
  select id as i from lemma.polygon_priority_areas
  LOOP 
    RAISE NOTICE 'Created_polygon %', i;
    INSERT INTO lemma.kmeans_result_pa1
    SELECT kmeans(ARRAY[ST_X(geom), ST_Y(geom)], (SELECT clusters FROM lemma.polygon_priority_areas WHERE id = i)) OVER (), "Pol.ID" as pol_id, 'key' as pixel_id, geom, "D_CONBM_kg" as yield
    FROM lemma.priority_areas
    WHERE lemma.priority_areas."Pol.ID" = i 
    ORDER BY pol_id;
    
  END LOOP;
  RETURN;
END; $$;

--DROP TABLE IF EXISTS lemma.kmeans_result_pa;
--CREATE TABLE lemma.kmeans_result_pa
--(kmeans integer, pol_id integer, id integer, geom geometry, yield double precision);

DO $$ 
BEGIN
  FOR i IN 397..1000 LOOP 
    INSERT INTO lemma.kmeans_result_pa
    SELECT kmeans(ARRAY[ST_X(geom), ST_Y(geom)], (SELECT clusters FROM lemma.polygon_priority_areas WHERE id = i)) OVER (), "Pol.ID" as pol_id, key as pixel_id, geom, "D_CONBM_kg" as yield
    FROM lemma.priority_areas
    WHERE lemma.priority_areas."Pol.ID" = i 
    ORDER BY pol_id;
  END LOOP;
END; $$



--Calculate the original center and weighted center, the result of center is in the 'sandbox.center_result'

﻿﻿DROP TABLE IF EXISTS sandbox.center_result;
CREATE TABLE sandbox.center_result AS
SELECT kmeans, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(yield) AS biomass, 
ST_SetSRID(ST_MakePoint(sum(ST_X(geom) * yield) / ((sum(yield)+1)), sum(ST_Y(geom) * yield) / (sum(yield)+1)), 5070) AS weighted_center_geom
FROM sandbox.kmeans_result
GROUP BY kmeans
ORDER BY kmeans;

SELECT pg_cancel_backend(procpid)
	FROM pg_stat_activity
	WHERE datname = 'baddatabase';
	

-- Distance to road 

Calculate the road point with nearest distance
ALTER TABLE sandbox.clustering_result 
ADD point_on_road geometry;

UPDATE sandbox.clustering_result
SET point_on_road = g1.point
FROM 
(SELECT kmeans_id, ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),ST_LineLocatePoint(ST_transform(weighted_road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
FROM sandbox.clustering_result) AS g1
WHERE sandbox.clustering_result.kmeans_id = g1.kmeans_id


DROP TABLE IF EXISTS sandbox.center_result;
CREATE TABLE sandbox.center_result AS
SELECT kmeans, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(yield) AS biomass, 
ST_SetSRID(ST_MakePoint(sum(ST_X(geom) * yield) / ((sum(yield)+1)), sum(ST_Y(geom) * yield) / (sum(yield)+1)), 5070) AS weighted_center_geom
FROM sandbox.kmeans_result_polygon
GROUP BY kmeans, pol_id
ORDER BY kmeans;



DROP TABLE IF EXISTS lemma.clustering_result_pa;
CREATE TABLE lemma.clustering_result_pa AS
SELECT DISTINCT ON(kmeans_id) g1.kmeans AS kmeans_id, g1.count AS kmeans_count, g1.biomass AS biomass, g1.weighted_center_geom AS weighted_center_geom, 
g2.id AS weighted_road_id, ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
g2.wkb_geometry AS weighted_road_geom
FROM lemma.cluster_center_pa As g1, roads_data.roads_california As g2
WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000)
ORDER BY kmeans_id, st_transform(g1.weighted_center_geom,5070) <-> st_transform(g2.wkb_geometry,5070);	


