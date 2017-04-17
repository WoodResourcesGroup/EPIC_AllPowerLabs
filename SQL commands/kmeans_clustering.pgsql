- Calculate the clusters and their information 
DROP TABLE IF EXISTS lemmav2.lemma_clusters;
CREATE TABLE lemmav2.lemma_clusters
(key integer, pol_id integer, kmeans_cluster_number integer, D_BM_kg double precision, geom geometry);

DO $$ 
declare 
	i lemmav2.lemma_clusterquantity.pol_id%TYPE;
BEGIN
  FOR i IN 
  -- this line makes sure only polygons with more than 1 cluster are crated.
  --select pol_id as i from lemmav2.lemma_clusterquantity where cluster_quantity > 1 and pol_id < 1215001688
  -- Temporary lines added to avoid problems with the abnormal polygons. The 1215001688 is based on the first group of polygons
  -- that don't present any problems. 
select pol_id as i from lemmav2.lemma_clusterquantity set 
  where cluster_quantity > 1 
  except (select pol_id from lemmav2.lemma_clusterabnormal) order by i asc 
  LOOP 
    INSERT INTO lemmav2.lemma_clusters
    SELECT pol_id_h[1] as pol_id, key as key, 
      ST_ClusterKMeans(geom, (SELECT cluster_quantity FROM lemmav2.lemma_clusterquantity WHERE pol_id = i)) OVER () as cluster_no, 
      "D_BM_kg_sum" as D_BM_kg, geom
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total.pol_id_h[1] = i 
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
  select pol_id as i, pol_area as area from lemmav2.lemma_clusterquantity where cluster_quantity = 1 and pol_id > 1215001580 and pol_area < 90298.6097
  order by area desc, i asc limit 10000
  LOOP 
    RAISE NOTICE 'Created_polygon %', i;
    INSERT INTO lemmav2.lemma_clusters
    SELECT pol_id_h[1] as pol_id, key as key, 
      0 as cluster_no, "D_BM_kg_sum" as D_BM_kg, geom
    FROM lemmav2.lemma_total
    WHERE lemmav2.lemma_total.pol_id_h[1] = i 
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
