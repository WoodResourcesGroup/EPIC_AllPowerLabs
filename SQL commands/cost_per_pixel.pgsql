
   slope                AYD             tpa                 vpt       
 1.83368390e-01   2.86414891e-03  -7.20761014e-03  -7.24520639e-02
slope^2            vpt^4
1.55842518e-03    7.61182893e-08

vpt^-1           vpt^-5
5.20663260e+01   -7.67803900e+00

tpa^-1
1.17558804e+01
  



 alter table lemma_kmeansclustering add column harvesting_cost numeric;
 update lemma_kmeansclustering set harvesting_cost = temp.cost from 
 (  select lemma_kmeansclustering.key, lemma_kmeansclustering.pol_id, slope, 3.28*yarding_distance as yarding_distance, 35.3147*vpt as vpt, dead_trees_acre,
 (0.183368390*slope + 0.00286414891*(3.28*yarding_distance) -0.00720761014*dead_trees_acre 
 -0.0724520639*(35.3147*vpt) +  1.55842518e-03 *slope^2 + 7.61182893e-08*(35.3147*vpt)^4 +52.0663260*(35.3147*vpt)^(-1.0) -7.67803900*(35.3147*vpt)^(-5.0) 
 + 11.7558804*dead_trees_acre^(-1.0) + 2.182) as cost from 
 lemma_kmeansclustering inner join lemma_total using (key,pol_id) inner join lemma_slope using (key,pol_id) where vpt <2.67 and slope <= 40) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  


 select lemma_kmeansclustering.key, lemma_kmeansclustering.pol_id, slope, 3.28*yarding_distance as yarding_distance, 35.3147*vpt as vpt, dead_trees_acre,
 (0.183368390*slope + 0.00286414891*(3.28*yarding_distance) -0.00720761014*dead_trees_acre 
 -0.0724520639*(35.3147*vpt) +  1.55842518e-03 *slope^2 + 7.61182893e-08*(35.3147*vpt)^4 +52.0663260*(35.3147*vpt)^(-1.0) -7.67803900*(35.3147*vpt)^(-5.0) 
 + 11.7558804*dead_trees_acre^(-1.0) + 2.182) as cost from 
 lemma_kmeansclustering inner join lemma_total using (key,pol_id) inner join lemma_slope using (key,pol_id) where vpt <2.67 and slope <= 40 limit 50;
 
 
 
  slope                AYD             tpa                 vpt   
  [  6.46668351e-03   0.00000000e+00  -2.46740120e-01  -3.89854333e-01
  slope^2           slope^4             AYD^2           tpa^2
   1.19708269e-05    2.05258053e-10   6.71364301e-06 5.66323514e-04  
   tpa^3                vpt^2           vpt^3
  -8.55224951e-10    2.50777059e-05   2.67770674e-08
    AYD^-1                                                  
   1.39472965e+03  -0.00000000e+00  -0.00000000e+00 
        vpt^-3
    -4.77298930e+02
    vpt^-1
 2.61917199e+02]


 update lemma_kmeansclustering set harvesting_cost = temp.cost from (
  select lemma_kmeansclustering.key, lemma_kmeansclustering.pol_id, slope, 3.28*yarding_distance as yarding_distance, 35.3147*vpt as vpt, dead_trees_acre,
 (6.46668351e-03*slope + 0*(3.28*yarding_distance) -2.46740120e-01 *dead_trees_acre  -3.89854333e-01*(35.3147*vpt) +  
 1.19708269e-05 *slope^2 + 2.05258053e-10*slope^4 +
 6.71364301e-06*(3.28*yarding_distance)^2+
 5.66323514e-04*(dead_trees_acre)^2 -8.55224951e-10*(dead_trees_acre)^3 +
 2.50777059e-05*(35.3147*vpt)^2 +2.67770674e-08*(35.3147*vpt)^3 +
 1.39472965e+03*(3.28*yarding_distance)^(-1)
 -4.77298930e+02*(35.3147*vpt)^(-3.0) + 2.61917199e+02 *(35.3147*vpt)^(-1.0)+ 
  30.390515629414864) as cost from 
 lemma_kmeansclustering inner join lemma_total using (key,pol_id) inner join lemma_slope using (key,pol_id) where vpt <2.67 and slope > 40 and yarding_distance < 396.24
 ) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  

  update lemma_kmeansclustering set harvesting_cost = temp.cost from (
        select lemma_kmeansclustering.key, lemma_kmeansclustering.pol_id, -1 as cost from lemma_kmeansclustering inner join lemma_total using (key,pol_id) where vpt  > 12) as temp where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  

 