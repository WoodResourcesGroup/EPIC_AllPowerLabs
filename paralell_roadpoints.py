import multiprocessing as multi
import cec_utils as ut
import pandas as pd

eng = ut.dbconfig(ut.user, ut.passwd, ut.dbname)
polyIds = pd.read_sql('select id as pid from lemma.polygon_priority_areas',
                      eng)


def closestRoad(polid, test=True):
    print 'finding road points for polygon {0}'.format(polid)
    con = eng.connect()
    sql = open('SQL commands/road_points_paralell.sql',
               'r').read().replace('\n',
                                   ' ').replace('\t',
                                                ' ')
    con.execute(sql)
    con.close()
    print 'found closest road point for {)}'.format(polid)


if __name__ == 'main':
    pool = multi.Pool()
    pool.map(closestRoad, polyIds)
    pool.close()
    pool.join()
