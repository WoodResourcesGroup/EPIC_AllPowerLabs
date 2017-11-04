

alter table lemma_dbscanclusters220 drop column if exists kmeans_cluster_no;
alter table lemma_dbscanclusters220 add column kmeans_cluster_no INT;
UPDATE lemma_dbscanclusters220 SET kmeans_cluster_no = temp.kmeans_cluster_number
from (SELECT key, pol_id, ST_ClusterKMeans(geom, 
     (SELECT kmeans_cluster_quantity FROM lemma_dbscancenters220 WHERE lemma_dbscancenters220.cluster_no = lemma_dbscanclusters220.cluster_no)) OVER (partition by cluster_no order by cluster_no) 
      as kmeans_cluster_number from lemma_dbscanclusters220 order by cluster_no) as temp 
where lemma_dbscanclusters220.key = temp.key and lemma_dbscanclusters220.pol_id = temp.pol_id; 








-- old queries using the approach based on the polygons 

- Calculate the clusters and their information 
DROP TABLE IF EXISTS lemmav2.lemma_clusters;
CREATE TABLE lemmav2.lemma_clusters
(pol_id integer, key integer, kmeans_cluster_number integer, D_BM_kg double precision, geom geometry);
alter table lemmav2.lemma_clusters add primary key (pol_id, key, kmeans_cluster_number);

DO $$ 
declare 
	i lemmav2.lemma_clusterquantity.pol_id%TYPE;
BEGIN
  FOR i IN 
select pol_id as i from lemmav2.lemma_clusterquantity  
  where cluster_quantity > 1 and pol_id <> 1215016202 order by i asc 
  LOOP 
    INSERT INTO lemmav2.lemma_clusters
    SELECT pol_id as pol_id, key as key, 
      ST_ClusterKMeans(geom, (SELECT cluster_quantity FROM lemmav2.lemma_clusterquantity WHERE pol_id = i)) OVER () as kmeans_cluster_number, 
      "D_BM_kg_sum" as D_BM_kg, geom
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total.pol_id = i 
    ORDER BY pol_id;
    RAISE NOTICE 'Created_polygon %', i; 
  END LOOP;
  RETURN;
END; $$;

   -- QUERY TO ADD TO THE CLUSTER TABLE THE POLYGONS WITH 1 CLUSTER ONLY
DO $$ 
declare 
	i lemmav2.lemma_clusterquantity.pol_id%TYPE;
BEGIN
  FOR i IN 
  -- this line makes sure only polygons with more than 1 cluster are crated.
  select pol_id as i, pol_area as area from lemmav2.lemma_clusterquantity where cluster_quantity = 1 and pol_area > 50000 
  order by area desc, i asc
  LOOP 
    RAISE NOTICE 'Created_polygon %', i;
    INSERT INTO lemmav2.lemma_clusters
    SELECT pol_id as pol_id, key as key, 
      0 as kmeans_cluster_number, "D_BM_kg_sum" as D_BM_kg, geom
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total.pol_id = i 
    ORDER BY pol_id;
  END LOOP;
  RETURN;
END; $$;

--- Tests for a 4 cluster polygon
    SELECT pol_id_h[1] as pol_id, key as key, 
      ST_ClusterKMeans(geom, (SELECT cluster_quantity FROM lemmav2.lemma_clusterquantity WHERE pol_id = 1215000001)) + 1  OVER (), 
      "D_BM_kg_sum" as D_BM_kg, geom
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total.pol_id_h[1] = 1215000001 
    ORDER BY pol_id;

-- Query to fix the keys in the table lemma clusters
set search_path = lemmav2, public; 
UPDATE lemma_clusters 
SET key = lemma_total.key
from lemma_total
where lemma_clusters.geom = lemma_total.geom;

-- Modified version of the query to create table 2. 