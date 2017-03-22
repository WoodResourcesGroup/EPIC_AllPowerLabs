--Calculate the number of clusters in each polygon, the result is stored in polygon
DROP TABLE IF EXISTS lemmav2.lemma_clusterquantity;
CREATE TABLE lemmav2.lemma_clusterquantity AS
-- The value in the divion of 101171 is equal to 25 acres in m^2
SELECT DISTINCT pol_id, CAST((floor(pol_area / 101171) + 1) AS INTEGER) AS cluster_quantity
FROM
(SELECT DISTINCT "Pol.ID" AS pol_id, "Pol.Shap_Ar" AS pol_area FROM lemmav2.lemma_total) ORDER BY "Pol.ID") AS pol
ORDER BY pol_id;