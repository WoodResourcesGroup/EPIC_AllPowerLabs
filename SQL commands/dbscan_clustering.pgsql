CREATE TABLE lemmav2.lemma_dbscanclusters AS
select key, ST_ClusterDBSCAN(geom, eps := 60, minpoints := 50) over () AS cluster_no, "D_BM_kg_sum" as D_BM_kg, geom
from lemmav2.lemma_total;

-- Standard distances calculations 

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters225;
CREATE TABLE lemmav2.lemma_dbscancenters225 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(d_bm_kg) AS biomass_total
FROM lemmav2.lemma_dbscanclusters225
GROUP BY cluster_no