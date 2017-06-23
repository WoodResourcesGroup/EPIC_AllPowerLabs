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