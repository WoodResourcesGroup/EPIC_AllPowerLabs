drop table if exists biomass.foo;
create table biomass.foo as with roads as (select st_transform(geom, 26910) geom from biomass."EnfTransportation" line 
	union select st_transform(geom, 26910) geom
	from biomass."TmuTransportation") select st_setsrid((st_dumppoints(st_simplify(st_union(geom), 1000))).geom, 26910) geom from roads;

alter table biomass.foo add column gid serial primary key;