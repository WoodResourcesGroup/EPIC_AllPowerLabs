-- obtain a portion of the data 
set search_path = lemma, general_gis_data, public;
SELECT * from lemma_crmort, "California_counties" as counties
	where st_within(lemma_crmort.geom, st_transform(counties.the_geom,5070)) 
	and counties.county in ('El Dorado', 'Amador', 'Mariposa', 'Alpine', 'Calaveras', 'Tuolumne', 'Madera', 'Fresno')

--Calculate the number of clusters in each polygon, the result is stored in polygon
DROP TABLE IF EXISTS lemma.polygon_clusters;
CREATE TABLE lemma.polygon_clusters AS
SELECT DISTINCT id, CAST(floor(area / 80937) AS INTEGER) AS clusters
FROM
(SELECT DISTINCT "Pol.ID" AS id, "Pol.Shap_Ar" AS area 
FROM lemma.priority_areas
ORDER BY "Pol.ID") AS pol
ORDER BY id;	

-- Query to obtain the abnormal/normal polygons 

create table lemma.invalid_pixels as
select p.* from lemma.priority_areas as p, 
(select "Pol.ID" from lemma.priority_areas group by "Pol.ID" having sum("D_CONBM_kg") > 80000) as f where p."Pol.ID" = f."Pol.ID" and p."D_CONBM_kg" > 0;

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

--Calculate the centers of the clusters, ignoring the zero valued pixels. This is an intermediate table 
-- Can be dropped later, the information is contained in the results.  

DROP TABLE IF EXISTS lemma.center_result_pa2;
CREATE TABLE lemma.center_result_pa2 AS
SELECT kmeans, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(yield) AS biomass, pol_id,
ST_SetSRID(ST_MakePoint(sum(ST_X(geom) * yield) / ((sum(yield))), sum(ST_Y(geom) * yield) / (sum(yield))), 5070) AS weighted_center_geom
FROM lemma.kmeans_result_pa2 where yield > 0
GROUP BY kmeans, pol_id
ORDER BY kmeans;

-- Distance calculation (not_functional)  

DROP TABLE IF EXISTS lemma.geometries_result_pa2;
CREATE TABLE lemma.geometries_result_pa2 AS
SELECT DISTINCT ON(kmeans_id, pol_id) g1.kmeans AS kmeans_id, pol_id, g1.count AS kmeans_count, g1.biomass AS biomass, g1.weighted_center_geom AS weighted_center_geom, 
g2.id AS weighted_road_id, ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
g2.wkb_geometry AS weighted_road_geom
FROM lemma.center_result_pa2 As g1, roads_data.roads_california As g2
WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000)
ORDER BY pol_id, kmeans_id, st_transform(g1.weighted_center_geom,5070) <-> st_transform(g2.wkb_geometry,5070);

ALTER TABLE lemma.geometries_result_pa2; 
ADD point_on_road geometry;
UPDATE lemma.geometries_result_pa2;
SET point_on_road = g1.point
FROM 
(SELECT kmeans_id, ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),ST_LineLocatePoint(ST_transform(weighted_road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
FROM lemma.geometries_result_pa2) AS g1
WHERE lemma.geometries_result_pa2.kmeans_id = g1.kmeans_id
group by pol_id;

-- Version 2 of the distance calculation query. The operator <-> doesn't really get the 
-- closest point. 

DROP TABLE IF EXISTS lemma.geometries_result_pa2;
CREATE TABLE lemma.geometries_result_pa2
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
    INSERT INTO lemma.geometries_result_pa2
    SELECT DISTINCT ON(kmeans_id) g1.kmeans AS kmeans_id, pol_id, g1.count AS kmeans_count, g1.biomass AS biomass, g1.weighted_center_geom AS weighted_center_geom, 
	g2.id AS weighted_road_id, ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
	g2.wkb_geometry AS weighted_road_geom
	FROM lemma.center_result_pa2 As g1, roads_data.roads_california As g2
	WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000) and g1.pol_id = pid
	ORDER BY kmeans_id, pol_id, kmeans_id, st_transform(g1.weighted_center_geom,5070) <-> st_transform(g2.wkb_geometry,5070);  
	
	UPDATE lemma.geometries_result_pa2
	SET point_on_road = ref.point
	FROM 
	(SELECT kmeans_id, pol_id, ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),ST_LineLocatePoint(ST_transform(weighted_road_geom,5070), ST_transform(weighted_center_geom,5070))) AS point
	FROM lemma.geometries_result_pa2 WHERE lemma.geometries_result_pa2.pol_id = pid) AS ref
	WHERE lemma.geometries_result_pa2.pol_id = ref.pol_id and lemma.geometries_result_pa2.kmeans_id = ref.kmeans_id;
	  
  END LOOP;
  RETURN;
END; $$;

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

-- Cost function calculation (based on the test_data table)

DROP TABLE IF EXISTS lemma.cost_result_pa2;
CREATE TABLE lemma.cost_result_pa2 AS
SELECT g1.pixel_id as pixels_id, g1.geom AS pixels_geom, g1.kmeans AS pixels_kmeans, g2.point_on_road AS road_geom,
ST_Distance(st_transform(g1.geom,5070),st_transform(g2.point_on_road,5070)) AS distance, g1.yield/1000 as total_gt
FROM lemma.kmeans_result_pa2 AS g1, lemma.clustering_result_pa2 AS g2
WHERE g1.kmeans = g2.kmeans_id and g1.pol_id = g2.pol_id and g1.yield > 0
ORDER BY pixels_id;

ALTER TABLE lemma.cost_result_pa2
ADD pixel_slope double precision;
ALTER TABLE lemma.cost_result_pa2
ADD diameter double precision;
ALTER TABLE lemma.cost_result_pa2
ADD total_gt double precision;
ALTER TABLE lemma.cost_result_pa2
ADD density_tree_m2 double precision;


UPDATE lemma.cost_result_pa2
SET pixel_slope = f.slope_perc, diameter = f."QMDC_DOM", density_tree_m2 = f.density
FROM (select lemma_slope.*, priority_areas."QMDC_DOM", priority_areas."D_CONBM_kg", priority_areas."Pol.NO_TREE"/priority_areas."Pol.Shap_Ar" as density from lemma.priority_areas 
		 join lemma.lemma_slope on priority_areas.key = lemma_slope.key) as f 
WHERE lemma.cost_result_pa2.pixels_id = f.id and f."D_CONBM_kg" > 0;


