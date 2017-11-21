--Calculate the centers of the clusters, ignoring the zero valued pixels. This is an intermediate table 
-- Can be dropped later, the information is contained in the results.  

DROP TABLE IF EXISTS lemmav2.lemma_kmeanscenters;
CREATE TABLE lemmav2.lemma_kmeanscenters AS
SELECT kmeans_cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(d_bm_kg) AS biomass_total, cluster_no, 
ST_SetSRID(ST_MakePoint(sum(ST_X(geom) * d_bm_kg) / ((sum(d_bm_kg))), sum(ST_Y(geom) * d_bm_kg) / (sum(d_bm_kg))), 5070) AS weighted_center_geom
FROM lemmav2.lemma_kmeansclustering
GROUP BY kmeans_cluster_no, cluster_no
ORDER BY cluster_no;


-- Query for later insertions and avoid repetitions

INSERT INTO lemmav2.lemma_clusterscenter (
SELECT kmeans_cluster_number, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, sum(d_bm_kg) AS biomass_total, pol_id,
ST_SetSRID(ST_MakePoint(sum(ST_X(geom) * d_bm_kg) / ((sum(d_bm_kg))), sum(ST_Y(geom) * d_bm_kg) / (sum(d_bm_kg))), 5070) AS weighted_center_geom
FROM lemmav2.lemma_clusters where pol_id = 1215016202
GROUP BY kmeans_cluster_number, pol_id
ORDER BY pol_id) ON CONFLICT (kmeans_cluster_number, pol_id) DO NOTHING;

-- Query to add the cluster areas using the count.

