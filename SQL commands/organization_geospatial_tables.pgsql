alter table lemma_dbscanclusters180 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters200 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters210 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters215 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters225 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters250 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters300 add primary key (key, pol_id, cluster_no);
alter table lemma_dbscanclusters400 add primary key (key, pol_id, cluster_no);

VACUUM ANALYZE lemma_dbscanclusters180;
VACUUM ANALYZE lemma_dbscanclusters200;
VACUUM ANALYZE lemma_dbscanclusters210;
VACUUM ANALYZE lemma_dbscanclusters215;
VACUUM ANALYZE lemma_dbscanclusters225;
VACUUM ANALYZE lemma_dbscanclusters250;
VACUUM ANALYZE lemma_dbscanclusters300;
VACUUM ANALYZE lemma_dbscanclusters400;

CREATE INDEX dbscanclusters180_gix ON lemma_dbscanclusters180 USING GIST (geom);
CREATE INDEX dbscanclusters200_gix ON lemma_dbscanclusters200 USING GIST (geom);
CREATE INDEX dbscanclusters210_gix ON lemma_dbscanclusters180 USING GIST (geom);
CREATE INDEX dbscanclusters215_gix ON lemma_dbscanclusters200 USING GIST (geom);
CREATE INDEX dbscanclusters225_gix ON lemma_dbscanclusters180 USING GIST (geom);
CREATE INDEX dbscanclusters250_gix ON lemma_dbscanclusters200 USING GIST (geom);
CREATE INDEX dbscanclusters300_gix ON lemma_dbscanclusters180 USING GIST (geom);
CREATE INDEX dbscanclusters400_gix ON lemma_dbscanclusters200 USING GIST (geom);

CLUSTER lemma_dbscanclusters180 USING dbscanclusters180_gix;
CLUSTER lemma_dbscanclusters200 USING dbscanclusters200_gix;
CLUSTER lemma_dbscanclusters210 USING dbscanclusters210_gix;
CLUSTER lemma_dbscanclusters215 USING dbscanclusters215_gix;
CLUSTER lemma_dbscanclusters225 USING dbscanclusters225_gix;
CLUSTER lemma_dbscanclusters250 USING dbscanclusters250_gix;
CLUSTER lemma_dbscanclusters300 USING dbscanclusters300_gix;

-- Find duplicates in tables A
select "Slope", "AYD", "ft3/CT", "CT/ac", count(*) from frcs_cost_large group by "Slope", "AYD", "ft3/CT", "CT/ac" HAVING count(*)>1 order by count;

DELETE FROM frcs_cost_large a USING (
      SELECT MIN(ctid) as ctid, "Slope", "AYD", "ft3/CT", "CT/ac"
        FROM frcs_cost_large 
        GROUP BY "Slope", "AYD", "ft3/CT", "CT/ac" HAVING COUNT(*) > 1
      ) b
      WHERE a."Slope" = b."Slope" AND
            a."AYD" = b."AYD" AND
            a."ft3/CT" = b."ft3/CT" AND
            a."CT/ac" = b."CT/ac"   AND 
            a.ctid <> b.ctid
