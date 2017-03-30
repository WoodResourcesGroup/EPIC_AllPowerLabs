-- Find Polygons with more clusters than rows 
set search_path  = lemmav2, public;
CREATE TABLE lemmav2.lemma_clusterabnormal as
select lemma_clusterquantity.pol_id, lemma_clusterquantity.cluster_quantity, foo.count_grouped from lemma_clusterquantity inner join 
(select pol_id_h[1] as pol_id_grouped, count(*) as count_grouped from lemma_total group by pol_id_h[1]) as foo ON
 lemma_clusterquantity.pol_id = foo.pol_id_grouped where lemma_clusterquantity.cluster_quantity >= foo.count_grouped and lemma_clusterquantity.cluster_quantity > 1
 order by pol_id