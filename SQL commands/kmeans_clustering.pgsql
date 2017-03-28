-- Calculate the clusters and their information 
DROP TABLE IF EXISTS lemmav2.lemma_clusters;
CREATE TABLE lemmav2.lemma_clusters
(kmeans_cluster_number integer, pol_id integer, geom geometry, D_BM_kg_sum double precision);

DO $$ 
declare 
	i lemmav2.lemma_clusterquantity.pol_id%TYPE;
BEGIN
  FOR i IN 
  -- this line makes sure only polygons with more than 1 cluster are crated.
  select pol_id as i from lemmav2.lemma_clusterquantity where cluster_quantity > 1
  LOOP 
    RAISE NOTICE 'Created_polygon %', i;
    INSERT INTO lemmav2.lemma_clusters
    SELECT ST_ClusterKMeans(geom, (SELECT cluster_quantity FROM lemmav2.lemma_clusterquantity WHERE pol_id = i)) OVER (), pol_id_h[1] as pol_id, geom, "D_BM_kg_sum" as D_BM_kg_sum 
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total.pol_id_h[1] = i 
    ORDER BY pol_id;
    
  END LOOP;
  RETURN;
END; $$;