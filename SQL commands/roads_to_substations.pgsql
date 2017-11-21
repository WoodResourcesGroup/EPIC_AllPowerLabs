set search_path = "PGE", lemmav2, public;
update feeders set geom_5070 = st_transform(geom,5070);


set search_path = "PGE", lemmav2, public;

create table lemmav2.substation_routes as
(SELECT
  road_points_clusters.landing_road as landing_road,
  road_points_clusters.row_number as landing_point,
  road_points_clusters.geom as landing_geom,
  feeders_d.feeder_no,
  feeders_d.name,
  feeders_d.geom as feeder_geom,
  ST_Distance(road_points_clusters.geom,feeders_d.geom) AS linear_distance
FROM
  road_points_clusters
CROSS JOIN LATERAL
  (SELECT feeder_no, name, geom_5070 as geom
   FROM feeders
   ORDER BY
     road_points_clusters.geom <-> geom_5070
   LIMIT 20) AS feeders_d);
alter table lemmav2.substation_routes add column landing_no numeric;  
update lemmav2.substation_routes set landing_no = (landing_road*1000 + landing_point);
alter table lemmav2.substation_routes add primary key (feeder_no, landing_no); 
alter table lemmav2.substation_routes add column api_distance numeric;
alter table lemmav2.substation_routes add column api_time numeric;
