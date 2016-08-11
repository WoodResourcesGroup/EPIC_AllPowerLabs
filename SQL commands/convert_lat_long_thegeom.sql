ALTER TABLE pge_ram.Feeders_data ADD COLUMN the_geom geometry(Point,4326); 
UPDATE pge_ram.Feeders_data set the_geom = ST_SetSRID(st_makepoint(Feeders_data.Lon, Feeders_data.Lat), 4326)::geometry;

