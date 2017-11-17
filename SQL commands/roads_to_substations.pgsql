set search_path = "PGE", lemmav2, public;
update feeders set geom_5070 = st_transform(geom,5070);


set search_path = "PGE", lemmav2, public;

create table lemmav2.substation_routes as
(SELECT
  road_cluster_test.landing_road as landing_road,
  road_cluster_test.row_number as landing_point,
  road_cluster_test.geom as landing_geom,
  feeders_d.feeder_no,
  feeders_d.name,
  feeders_d.geom as feeder_geom,
  ST_Distance(road_cluster_test.geom,feeders_d.geom) AS linear_distance
FROM
  road_cluster_test
CROSS JOIN LATERAL
  (SELECT feeder_no, name, geom_5070 as geom
   FROM feeders
   ORDER BY
     road_cluster_test.geom <-> geom_5070
   LIMIT 10) AS feeders_d);

