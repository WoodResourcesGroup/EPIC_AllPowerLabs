
# !/usr/bin/env python
# -*- coding: utf-8 -*-
# Deployment model for distributed gasifiers
# Jose Daniel Lara

from __future__ import division
from pyomo.environ import *
import googlemaps
import matplotlib.pyplot as plt

size = [1, 2, 3, 5, 10]
cost = [5000, 6500, 7500, 9300, 13000]

model = ConcreteModel()


def slope_calculation(x, y):
    c = []
    d = []
    for i, val_x in enumerate(x):
        if i < len(x) - 1:
            mc = (y[i] - y[i + 1]) / (x[i] - x[i + 1])
            md = y[i + 1] - mc * x[i + 1]
            c.append(mc)
            d.append(md)
            c_dict = dict(zip(range(1, len(x)), c))
            d_dict = dict(zip(range(1, len(x)), d))
    return c_dict, d_dict

c, d = slope_calculation(size, cost)

print c
print d

model.PW = Set(initialize=range(1, len(size) + 1), doc='Set for the PW approx')

model.c = Param(model.PW, initialize=c, doc='PW c_i')

model.c.display()

plt.plot(size, cost)
plt.show()
