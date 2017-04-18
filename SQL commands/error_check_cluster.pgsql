-- Find Polygons with more clusters than rows 
set search_path  = lemmav2, public;
CREATE TABLE lemmav2.lemma_clusterabnormal as
select lemma_clusterquantity.pol_id, lemma_clusterquantity.cluster_quantity, foo.count_grouped from lemma_clusterquantity inner join 
<<<<<<< .merge_file_FXE3v5
(select pol_id as pol_id_grouped, count(*) as count_grouped from lemma_total group by pol_id) as foo ON
=======
(select pol_id_h[1] as pol_id_grouped, count(*) as count_grouped from lemma_total group by pol_id_h[1]) as foo ON
>>>>>>> .merge_file_aTIaDR
 lemma_clusterquantity.pol_id = foo.pol_id_grouped where lemma_clusterquantity.cluster_quantity >= foo.count_grouped and lemma_clusterquantity.cluster_quantity > 1
 order by pol_id

 set search_path  = lemmav2, public;
CREATE TABLE lemmav2.lemma_clusterabnormal2 as
