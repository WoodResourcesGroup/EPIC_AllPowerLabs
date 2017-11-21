INSERT INTO lemma.geometries_result_pav2
SELECT DISTINCT ON(kmeans_id) g1.kmeans AS kmeans_id,
       pol_id,
       g1.count AS kmeans_count,
       g1.biomass AS biomass,
       g1.weighted_center_geom AS weighted_center_geom, 
       g2.id AS weighted_road_id,
       ST_Distance(st_transform(g1.weighted_center_geom,5070),st_transform(g2.wkb_geometry,5070)) AS weighted_distance, 
       g2.wkb_geometry AS weighted_road_geom
FROM lemma.center_result_pa2 As g1, roads_data.roads_california As g2
WHERE ST_DWithin(st_transform(g1.weighted_center_geom,5070), st_transform(g2.wkb_geometry,5070), 1000) and g1.pol_id = {0}
ORDER BY kmeans_id, pol_id, kmeans_id, weighted_distance;  
UPDATE lemma.geometries_result_pav2
SET point_on_road = ref.point
FROM (SELECT kmeans_id,
     pol_id,
     ST_LineInterpolatePoint(ST_transform(weighted_road_geom,5070),
     ST_LineLocatePoint(ST_transform(weighted_road_geom,5070),
     ST_transform(weighted_center_geom,5070))) AS point
     FROM lemma.geometries_result_pav2
WHERE lemma.geometries_result_pav2.pol_id = {0}) AS ref
WHERE lemma.geometries_result_pav2.pol_id = ref.pol_id
and lemma.geometries_result_pav2.kmeans_id = ref.kmeans_id;

select "PGE".substations.lat as source_lat, "PGE".substations.lon as source_lon, 
        "PGE".feeders.lat as dest_lat, "PGE".feeders.lon as dest_lon 
        FROM "PGE".feeders, "PGE".substations where st_distance("PGE".substations.geom, "PGE".feeders.geom) < 1 limit 10;