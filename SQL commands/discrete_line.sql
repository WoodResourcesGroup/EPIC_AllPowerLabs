﻿    SELECT biomass."AnfTransportation".id, biomass."AnfTransportation".shape_leng, (ST_DumpPoints(biomass."AnfTransportation".geom)).path[2], ST_setsrid((ST_DumpPoints(biomass."AnfTransportation".geom)).geom, 26911) as the_geom
    FROM biomass."AnfTransportation" limit 30