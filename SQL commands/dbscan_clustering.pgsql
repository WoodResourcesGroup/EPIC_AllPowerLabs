CREATE TABLE lemmav2.lemma_dbscanclusters215 AS
select key, ST_ClusterDBSCAN(geom, eps := 215, minpoints := 112) over () AS cluster_no, "D_BM_kg_sum" as D_BM_kg, geom
from lemmav2.lemma_total;

CREATE TABLE lemmav2.lemma_dbscanclusters210 AS
select key, ST_ClusterDBSCAN(geom, eps := 210, minpoints := 112) over () AS cluster_no, "D_BM_kg_sum" as D_BM_kg, geom
from lemmav2.lemma_total;

CREATE TABLE lemmav2.lemma_dbscanclusters150 AS
select key, ST_ClusterDBSCAN(geom, eps := 150, minpoints := 112) over () AS cluster_no, "D_BM_kg_sum" as D_BM_kg, geom
from lemmav2.lemma_total;

-- Standard distances calculations 

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters215;
CREATE TABLE lemmav2.lemma_dbscancenters215 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(d_bm_kg) AS biomass_total
FROM lemmav2.lemma_dbscanclusters215
GROUP BY cluster_no

-- sum of square of distances calculation

alter table lemma_dbscancenters200 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters200 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters200 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters200.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters200.geom, lemma_dbscancenters200.center_geom)^2.0) as dist from lemma_dbscanclusters200, lemma_dbscancenters200 where 
lemma_dbscancenters200.cluster_no = lemma_dbscanclusters200.cluster_no group by lemma_dbscancenters200.cluster_no) as temp where lemmav2.lemma_dbscancenters200.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters300 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters300 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters300 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters300.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters300.geom, lemma_dbscancenters300.center_geom)^2.0) as dist from lemma_dbscanclusters300, lemma_dbscancenters300 where 
lemma_dbscancenters300.cluster_no = lemma_dbscanclusters300.cluster_no group by lemma_dbscancenters300.cluster_no) as temp where lemmav2.lemma_dbscancenters300.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters400 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters400 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters400 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters400.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters400.geom, lemma_dbscancenters400.center_geom)^2.0) as dist from lemma_dbscanclusters400, lemma_dbscancenters400 where 
lemma_dbscancenters400.cluster_no = lemma_dbscanclusters400.cluster_no group by lemma_dbscancenters400.cluster_no) as temp where lemmav2.lemma_dbscancenters400.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters250 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters250 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters250 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters250.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters250.geom, lemma_dbscancenters250.center_geom)^2.0) as dist from lemma_dbscanclusters250, lemma_dbscancenters250 where 
lemma_dbscancenters250.cluster_no = lemma_dbscanclusters250.cluster_no group by lemma_dbscancenters250.cluster_no) as temp where lemmav2.lemma_dbscancenters250.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters225 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters225 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters225 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters225.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters225.geom, lemma_dbscancenters225.center_geom)^2.0) as dist from lemma_dbscanclusters225, lemma_dbscancenters225 where 
lemma_dbscancenters225.cluster_no = lemma_dbscanclusters225.cluster_no group by lemma_dbscancenters225.cluster_no) as temp where lemmav2.lemma_dbscancenters225.cluster_no = temp.clust_no; 

-- standard distances calculation

alter table lemma_dbscancenters200 drop column if exists standard_distance;
alter table lemma_dbscancenters200 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters200 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters300 drop column if exists standard_distance;
alter table lemma_dbscancenters300 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters300 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters400 drop column if exists standard_distance;
alter table lemma_dbscancenters400 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters400 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters250 drop column if exists standard_distance;
alter table lemma_dbscancenters250 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters250 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters225 drop column if exists standard_distance;
alter table lemma_dbscancenters225 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters225 SET standard_distance = sqrt(sum_distances_sq/count);

