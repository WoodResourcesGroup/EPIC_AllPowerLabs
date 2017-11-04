-- Updated approach based on DBSCAN clustering instead of the polygon based approach

alter table lemma_dbscancenters180 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters180 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters180 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters200 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters200 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters200 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters210 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters210 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters210 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters215 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters215 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters215 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters225 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters225 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters225 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters250 drop column if exists kmeans_cluster_quantity; 
alter table lemma_dbscancenters250 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters250 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters300 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters300 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters300 SET kmeans_cluster_quantity = floor(count/112);

alter table lemma_dbscancenters400 drop column if exists kmeans_cluster_quantity;
alter table lemma_dbscancenters400 add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_dbscancenters400 SET kmeans_cluster_quantity = floor(count/112);


-- Old queries for approach based on polygons----

--Calculate the number of clusters in each polygon, the result is stored in clusterquantity
DROP TABLE IF EXISTS lemmav2.lemma_clusterquantity;
CREATE TABLE lemmav2.lemma_clusterquantity AS
-- The value in the divion of 101171 is equal to 25 acres in m^2
SELECT DISTINCT pol_id, pol_area, pixel_area,
CAST((floor(least(pol.pol_area,pol.pixel_area) / 101171) + 1) AS INTEGER) AS cluster_quantity
FROM
(SELECT DISTINCT pol_id AS pol_id, max(pol_area) as pol_area, count(*)*900 as pixel_area FROM lemmav2.lemma_total group by pol_id) AS pol
ORDER BY pol_id;
alter table lemmav2.lemma_clusterquantity add primary KEY (pol_id);