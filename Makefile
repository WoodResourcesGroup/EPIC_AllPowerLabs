 #Change this to the target database 
dbname := cec
usgsFTP := ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/MapIndices/Shape/
usgs13FTP := ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/Elevation/13/
caidxurl := https://prd-tnm.s3.amazonaws.com/StagedProducts/MapIndices/Shape/
caIndex := CELLS_6_California_GU_STATEORTERRITORY.zip
dbdir := cecdb
PG := psql -h switch-db2.erg.berkeley.edu -d apl_cec -U ptittmann
#this works when password is stored in ~/.pgpass per https://www.postgresql.org/docs/9.4/static/libpq-pgpass.html
demSchema = elevation

#Table name in th database
pxTableName := lemma_biomass

 #Change this to the target schema
pxSchema := public

 #this should be the csv file
srcFile := 'sandbox/Trial_Biomass_Pixels_LEMMA_6.csv'


# this is just used to make a temporary database, the switch-db2.erg.berkeley.edu
${dbname}db:
	createdb ${dbname}
	psql -d ${dbname} -c 'create extension postgis;'
	curl https://epsg.io/5070-1252.sql?download | psql -d ${dbname}
	mkdir $@

.PHONY: db
db:${dbname}db

# this is the target to migrate the csv to the database.
# once you have the variables defines above run the following from the same direcotyr as the Makefile: 'make <dbname>db/px2db'

${dbname}db/px2db:
	./px2db.py ${srcFile} ${dbname} ${pxSchema} ${pxTableName}
	psql -d ${dbname} -c "SELECT AddGeometryColumn ('${pxSchema}','${pxTableName}','geom',5070,'POINT',2);"
	psql -d ${dbname} -c "update ${pxTableName} set geom = st_setsrid(st_makepoint(x,y),5070);"
	touch $@

#####
# Elevation data
#####

#Schema

${dbdir}/demSchema:
	${PG} -c 'drop schema if exists ${demSchema};'
	${PG} -c 'create schema ${demSchema};'
	touch $@

${dbdir}/usgs_index:
	rm -rf $(@F)
	mkdir $(@F)
	wget ${caidxurl}${caIndex} -O $(@F)/$(@F).zip
	unzip $(@F)/$(@F).zip -d $(@F)
	shp2pgsql -d -s 4269:5070 -I $(@F)/Shape/CellGrid_1X1Degree.shp ${demSchema}.usgs375 |${PG}
	rm -rf $(@F)
	touch $@



# ${dbdir}/usgs_13_idx:
# 	rm -rf $(@F)
# 	mkdir $(@F)
# 	wget ${usgs13FTP}${usgs13idx} -O $(@F)/$(@F).zip
# 	unzip $(@F)/$(@F).zip -d $(@F)
# 	shp2pgsql -d -s 4269:5070 -I $(@F)/Shape/CellGrid_3_75Minute.shp ${demSchema}.usgs375 |${PG}
# 	shp2pgsql -d -s 4269:5070 -I $(@F)/Shape/CellGrid_7_5Minute.shp ${demSchema}.usgs75 |${PG}
# 	rm -rf $(@F)
# 	touch $@


.PHONY: elev
elev: ${dbdir}/demSchema ${dbdir}/usgs_index

FRCS:
	mkdir $@

.PHONY: frcs_input
frcs_input: FRCS
	python -c 'import cec_utils as ut; ut.iterHarvestSystems()'
