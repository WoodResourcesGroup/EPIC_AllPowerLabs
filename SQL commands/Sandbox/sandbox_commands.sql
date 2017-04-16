 SELECT "AnfTransportation".id, "AnfTransportation".shape_leng, 
 (st_dumppoints("AnfTransportation".geom)).path[2] AS path, 
 st_setsrid((st_dumppoints("AnfTransportation".geom)).geom, 26911) AS the_geom
   FROM biomass."AnfTransportation";
   
 CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTILINESTRING'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4326)
  
  