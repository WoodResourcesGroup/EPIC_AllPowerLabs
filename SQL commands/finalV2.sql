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

-- OLD Distance calculation (doesn't work well)  

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
FROM lemma.clustering_result_pa2) AS g1
WHERE lemma.clustering_result_pa2.kmeans_id = g1.kmeans_id
group by pol_id;

-- New version of the distance calculation query. 

DROP TABLE IF EXISTS lemma.clustering_result_pa2;
CREATE TABLE lemma.clustering_result_pa2
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
    INSERT INTO lemma.clustering_result_pa2
    SELECT DISTINCT ON(kmeans_id) g1.kmeans AS kmeans_id, pol_id, g1.count AS kmeans_count, g1.biomass AS biomass, g1.weighted_center_geom AS weighted_center_geom, 
	g2.id AS weighted_road_id, ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
	g2.wkb_geometry AS weighted_road_geom
	FROM lemma.center_result_pa2 As g1, roads_data.roads_california As g2
	WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000) and g1.pol_id = pid
	ORDER BY kmeans_id, pol_id, kmeans_id, st_transform(g1.weighted_center_geom,5070) <-> st_transform(g2.wkb_geometry,5070);  
	
	UPDATE lemma.clustering_result_pa2
	SET point_on_road = ref.point
	FROM 
	(SELECT kmeans_id, pol_id, ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),ST_LineLocatePoint(ST_transform(weighted_road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
	FROM lemma.clustering_result_pa2 WHERE lemma.clustering_result_pa2.pol_id = pid) AS ref
	WHERE lemma.clustering_result_pa2.pol_id = ref.pol_id and lemma.clustering_result_pa2.kmeans_id = ref.kmeans_id;
	  
  END LOOP;
  RETURN;
END; $$;

-- Cost function calculation (based on the test_data)

DROP TABLE IF EXISTS lemma.cost_result_test;
CREATE TABLE lemma.cost_result_test AS
SELECT g1.pixel_id as pixels_id, g1.geom AS pixels_geom, g1.kmeans AS pixels_kmeans, g2.point_on_road AS road_geom,
ST_Distance(st_transform(g1.geom,5070),st_transform(g2.point_on_road,5070)) AS distance, g1.yield
FROM lemma.kmeans_result_pa2 AS g1, lemma.clustering_result_test AS g2
WHERE g1.kmeans = g2.kmeans_id and g1.pol_id = g2.pol_id and g1.yield > 0
ORDER BY pixels_id;

ALTER TABLE lemma.cost_result_test
ADD pixel_slope double precision;
ALTER TABLE lemma.cost_result_test
ADD diameter double precision;
ALTER TABLE lemma.cost_result_test
ADD total_gt double precision;


UPDATE lemma.cost_result_test
SET pixel_slope = f.slope, diameter = f."QMDC_DOM", total_gt = f."D_CONBM_kg"
FROM (select lemma_elev_slope_rs.*, priority_areas."QMDC_DOM", priority_areas."D_CONBM_kg" from lemma.priority_areas 
		join lemma.lemma_elev_slope_rs on priority_areas.key = lemma_elev_slope_rs.id) as f 
WHERE lemma.cost_result_test.pixels_id = f.id and f."D_CONBM_kg" > 0;

