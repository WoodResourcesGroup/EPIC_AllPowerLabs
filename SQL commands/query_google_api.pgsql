
select  ST_Y(ST_Transform(landing_geom,4326)) as source_lat, ST_X(ST_Transform(landing_geom,4326)) as source_lon, landing_no as source_id, 
ST_Y(ST_Transform(feeder_geom,4326)) as dest_lat, ST_X(ST_Transform(feeder_geom,4326)) as dest_lon, feeder_no as dest_id 
FROM substation_routes limit 10;


'UPDATE substation_routes set api_distance =' + str(distance)+','+ 'api_time = '+ str(time) + ' where landing_no =' + str(source[1]) +' and '+ 'feeder_no =' + str(sink[1]) +';' 