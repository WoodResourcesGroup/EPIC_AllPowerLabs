CREATE TABLE lemmav2.lemma_dbscanclusters AS
select key, ST_ClusterDBSCAN(geom, eps := 60, minpoints := 50) over () AS cluster_no, "D_BM_kg_sum" as D_BM_kg, geom
from lemmav2.lemma_total;