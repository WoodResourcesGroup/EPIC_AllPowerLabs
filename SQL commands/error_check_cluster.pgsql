-- Find Polygons with more clusters assigned than rows 
set search_path  = lemmav2, public;
drop table lemma_clusterabnormal;
CREATE TABLE lemmav2.lemma_clusterabnormal as
select lemma_clusterquantity.pol_id, lemma_clusterquantity.cluster_quantity, foo.count_grouped from lemma_clusterquantity inner join 
(select pol_id_h[1] as pol_id_grouped, count(*) as count_grouped from lemma_total group by pol_id_h[1]) as foo ON
 lemma_clusterquantity.pol_id = foo.pol_id_grouped where lemma_clusterquantity.cluster_quantity >= foo.count_grouped and lemma_clusterquantity.cluster_quantity > 1
 order by pol_id


-- check the pixels with the abnormal numbers A

set search_path  = lemmav2, public;
select lemma_total.* from lemma_total, lemma_clusterabnormal where lemma_total.pol_id = lemma_clusterabnormal.pol_id; 

-- 
set search_path  = lemmav2, public;
update lemma_total set pol_id = pol_id_h[1] where pol_id_h[2] is NULL and lemma_total.pol_id[2] in (select pol_id from lemma_clusterabnormal); 

-- drop the pizels with 0 and also abnormal values. A
set search_path  = lemmav2, public;
delete from lemma_total where "D_BM_kg_sum" = 0 and lemma_total.pol_id in (select pol_id from lemma_clusterabnormal); 

-- Correction code 1 
set search_path  = lemmav2, public;
select abnormal.pol_id, final_pol.pol_id from
	(select pol_id, geom 
	from lemma_total where lemma_total.pol_id in (select pol_id from lemma_clusterabnormal)) as abnormal
cross join lateral
	(select clean_lemma.pol_id from 
		(select lemma_total.* from lemma_total where lemma_total.pol_id not in (select pol_id from lemma_clusterabnormal)) as clean_lemma
ORDER BY abnormal.geom <-> clean_lemma.geom limit 1) as final_pol;