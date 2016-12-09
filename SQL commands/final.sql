-- obtain a portion of the data 
set search_path = lemma, general_gis_data, public;
SELECT * from lemma_crmort, "California_counties" as counties
	where st_within(lemma_crmort.geom, st_transform(counties.the_geom,5070)) 
	and counties.county in ('El Dorado', 'Amador', 'Mariposa', 'Alpine', 'Calaveras', 'Tuolumne', 'Madera', 'Fresno')

--Calculate the number of clusters in each polygon, the result is stored in polygon
DROP TABLE IF EXISTS lemma.polygon_priority_areas;
CREATE TABLE lemma.polygon_priority_areas AS
SELECT DISTINCT id, CAST(floor(area / 80937) AS INTEGER) AS clusters
FROM
(SELECT DISTINCT "Pol.ID" AS id, "Pol.Shap_Ar" AS area 
FROM lemma.priority_areas
ORDER BY "Pol.ID") AS pol
ORDER BY id;	

-- Calculate the clusters and their information 
DROP TABLE IF EXISTS lemma.kmeans_result_pa2;
CREATE TABLE lemma.kmeans_result_pa2
(kmeans integer, pol_id integer, pixel_id integer, geom geometry, yield double precision);

DO $$ 
declare 
	i lemma.polygon_priority_areas.id%TYPE;
BEGIN
  FOR i IN 
  select id as i from lemma.polygon_priority_areas
  LOOP 
    RAISE NOTICE 'Created_polygon %', i;
    INSERT INTO lemma.kmeans_result_pa2
    SELECT kmeans(ARRAY[ST_X(geom), ST_Y(geom)], (SELECT clusters FROM lemma.polygon_priority_areas WHERE id = i)) OVER (), "Pol.ID" as pol_id, key as pixel_id, geom, "D_CONBM_kg" as yield
    FROM lemma.priority_areas
    WHERE lemma.priority_areas."Pol.ID" = i 
    ORDER BY pol_id;
    
  END LOOP;
  RETURN;
END; $$;

--Calculate the centers of the clusters, ignoring the zero valued pixels. 

DROP TABLE IF EXISTS lemma.center_result_pa2;
CREATE TABLE lemma.center_result_pa2 AS
SELECT kmeans, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(yield) AS biomass, pol_id,
ST_SetSRID(ST_MakePoint(sum(ST_X(geom) * yield) / ((sum(yield))), sum(ST_Y(geom) * yield) / (sum(yield))), 5070) AS weighted_center_geom
FROM lemma.kmeans_result_pa2 where yield > 0
GROUP BY kmeans, pol_id
ORDER BY kmeans;

-- Distance calculation (still being tested), doesn't show progress  

DROP TABLE IF EXISTS lemma.clustering_result_pa2;
CREATE TABLE lemma.clustering_result_pa2 AS
SELECT DISTINCT ON(kmeans_id, pol_id) g1.kmeans AS kmeans_id, pol_id, g1.count AS kmeans_count, g1.biomass AS biomass, g1.weighted_center_geom AS weighted_center_geom, 
g2.id AS weighted_road_id, ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
g2.wkb_geometry AS weighted_road_geom
FROM lemma.center_result_pa2 As g1, roads_data.roads_california As g2
WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000)
ORDER BY pol_id, kmeans_id, st_transform(g1.weighted_center_geom,5070) <-> st_transform(g2.wkb_geometry,5070);

ALTER TABLE lemma.clustering_result_pa2; 
ADD point_on_road geometry;
UPDATE lemma.clustering_result_pa2;
SET point_on_road = g1.point
FROM 
(SELECT kmeans_id, ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),ST_LineLocatePoint(ST_transform(weighted_road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
FROM sandbox.clustering_result) AS g1
WHERE lemma.clustering_result_pa2.kmeans_id = g1.kmeans_id
group by pol_id;

	
	