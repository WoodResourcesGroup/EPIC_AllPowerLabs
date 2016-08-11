COLUMN	FULL CODE	UNITS	ORIGIN(S)	EXPLANATION/METHOD
RPT_YR	Year Reported	year	DroughtTreeMortality.gdb	
TPA	Dead Trees Per Acre	trees per acre	DroughtTreeMortality.gdb	
NO_TREE	Number of Dead Trees	number of trees	DroughtTreeMortality.gdb	
FOR_TYP	Forest Type	code	DroughtTreeMortality.gdb	
Shap_Ar	Polygon Area	meters	DroughtTreeMortality.gdb	
TOT_CONBM_kgha	Biomass of all conifers 	kg/ha	"DroughtTreeMortality.gdb, LEMMA"	weighted biomass of all conifers (BPHC_GE_3_CRM) by pixel frequency and then summed them
CON_THA	Trees per Hectare 	trees per hectare	LEMMA	weighted live conifer density (TPHC_GE_3) by raster pixel and then summed them
QMDC_DOM	Quadratic mean diameter of all dominant and codominant conifers	cm	LEMMA	arithmetic mean of QMDC_DOM across all pixels in the polygon
CONPL	conifer plurality	species code	LEMMA	most common of the conifer species to have a plurality in each raster cell
Av_BM_TR	Average biomass per tree	kg	LEMMA	divide CONBM_kg_pol by NO_TREE
CONBM_kg_pol	Total dead conifer biomass in the polygon		"DroughtTreeMortality.gdb, LEMMA"	multiplied number of trees by biomass calculated from allometric equations based on QMDC_DOM
Cent.x	Centroid x		DroughtTreeMortality.gdb	"X coordinate of centroid of polygon, EPSG 5070"
Cent.y	Centroid y		DroughtTreeMortality.gdb	"Y coordinate of centroid of polygon, EPSG 5070"
est.tot.con	estimated total conifers	trees	"DroughtTreeMortality.gdb, LEMMA"	mulitiplied CON_THA by polygon size in hectares
est.tot.con.BM	estimated total conifer biomass	kg	"DroughtTreeMortality.gdb, LEMMA"	multiplied TOT_CONBM_kgha by polygon size in hectares
				
				
				
*** This analysis assumes that all dead  trees are conifers				
