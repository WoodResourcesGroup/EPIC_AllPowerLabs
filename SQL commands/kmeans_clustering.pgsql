
-- This has the same problem that if it fails at one cluster, fails for all
alter table lemma_kmeansclustering drop column if exists kmeans_cluster_no;
alter table lemma_kmeansclustering add column kmeans_cluster_no INT;

  UPDATE lemma_kmeansclustering SET kmeans_cluster_no = temp.kmeans_cluster_number
  from (SELECT key, pol_id, ST_ClusterKMeans(geom, 
      (SELECT kmeans_cluster_quantity FROM lemma_kmeanscenters WHERE lemma_kmeanscenters.cluster_no = lemma_kmeansclustering.cluster_no)) OVER (partition by cluster_no order by cluster_no) 
        as kmeans_cluster_number from lemma_kmeansclustering order by cluster_no) as temp 
  where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id = temp.pol_id and cluster_no == i; 



UPDATE lemmav2.lemma_kmeansclustering SET cluster_no = temp.kmeans_cluster_number from (SELECT key, pol_id, ST_ClusterKMeans(geom, 100) OVER () as kmeans_cluster_number from lemmav2.lemma_kmeansclustering where cluster_no = 934) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id = temp.pol_id;

Update dbscanclusters220 set cluster_no = temp.kmeans_cluster_number  from (SELECT key, pol_id, (cluster_no*1000+ST_ClusterKMeans(geom, 10) OVER ()) as kmeans_cluster_number from lemmav2.lemma_kmeansclustering where cluster_no = 1517) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id = temp.pol_id;


UPDATE lemmav2.lemma_kmeansclustering SET kmeans_cluster_no = NULL where cluster_no >= 93400;


Update lemmav2.lemma_kmeansclustering set cluster_no = temp.new_cluster from (select key, pol_id, (lemma_kmeansclustering.cluster_no + 4) as new_cluster from lemma_kmeansclustering, (select cluster_no from lemma_kmeanscenters where kmeans_cluster_quantity < 1) as t where lemma_kmeansclustering.cluster_no = t.cluster_no) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id = temp.pol_id;
DROP TABLE IF EXISTS lemmav2.lemma_kmeanscenters;
CREATE TABLE lemmav2.lemma_kmeanscenters AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(d_bm_kg) AS biomass_total
FROM lemmav2.lemma_kmeansclustering
GROUP BY cluster_no;
alter table lemma_kmeanscenters drop column if exists kmeans_cluster_quantity;
alter table lemma_kmeanscenters add column kmeans_cluster_quantity INT;
UPDATE lemmav2.lemma_kmeanscenters SET kmeans_cluster_quantity = floor(count/112);
select sum(count) from lemma_kmeanscenters where kmeans_cluster_quantity < 1;     

UPDATE lemma_kmeansclustering SET kmeans_cluster_no = temp.new_kmeans, cluster_no = temp.new_cluster from
(select bad_pixels.*, lemma_t.cluster_no as new_cluster, lemma_t.kmeans_cluster_no as new_kmeans from 
(select key, pol_id, lemma_kmeansclustering.cluster_no, lemma_kmeansclustering.kmeans_cluster_no, geom from lemma_kmeansclustering, 
(select cluster_no, kmeans_cluster_no from lemma_kmeanscenters where count < 112) as t 
where lemma_kmeansclustering.cluster_no = t.cluster_no and lemma_kmeansclustering.kmeans_cluster_no = t.kmeans_cluster_no) as bad_pixels 
CROSS JOIN LATERAL
(Select cluster_no, kmeans_cluster_no from lemma_kmeansclustering where 
(cluster_no,kmeans_cluster_no) not in (select cluster_no, kmeans_cluster_no from lemma_kmeanscenters where count < 112)
order by bad_pixels.geom <-> geom limit 1) as lemma_t
) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id = temp.pol_id; 

select key, pol_id, lemma_kmeansclustering.cluster_no, lemma_kmeansclustering.kmeans_cluster_no, geom from lemma_kmeansclustering, 
(select cluster_no, kmeans_cluster_no from lemma_kmeanscenters where count < 112) as t 
where lemma_kmeansclustering.cluster_no = t.cluster_no and lemma_kmeansclustering.kmeans_cluster_no = t.kmeans_cluster_no limit 10


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