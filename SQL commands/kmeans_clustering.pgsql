-- Calculate the clusters and their information 
DROP TABLE IF EXISTS lemmav2.lemma_clusters;
CREATE TABLE lemmav2.lemma_clusters
(key integer, kmeans_cluster_number integer, pol_id integer, geom geometry, D_BM_kg double precision);

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
    SELECT ST_ClusterKMeans(geom, (SELECT cluster_quantity FROM lemmav2.lemma_clusterquantity WHERE pol_id = i)) OVER (), "Pol.ID" as pol_id, key as key, geom, "D_BM_kg" as D_BM_kg
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total."Pol.ID" = i 
    ORDER BY pol_id;
    
  END LOOP;
  RETURN;
END; $$;