#!/usr/bin/env python

import pandas as pd
import cec_utils as ut
import sys

src_file = sys.argv[1]
dbname = sys.argv[2]
sch = sys.argv[3]
tblname = sys.argv[4]

eng = ut.dbconfig(dbname)
data = pd.read_csv(src_file)
data.columns = [i.lower() for i in data.columns]
data.to_sql(tblname, eng, schema=sch, if_exists="replace")
