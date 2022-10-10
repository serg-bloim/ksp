import csv
import math
from enum import Enum, auto
from math import sqrt

_body_data = {}
with open('body.csv', newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='|')
    next(reader)  # skip headers
    for row in reader:
        row = [x.strip() for x in row]
        name = row[0]
        _body_data[name] = [float(x) for x in row[1:]]


class Body(Enum):
    Kerbin = auto()
    Mun = auto()
    Minmus = auto()

    def __init__(self, val) -> None:
        self.radius, self.mu, self.axisperiod = _body_data[self.name]

    def get_period(self, alt):
        h = alt + self.radius
        return 2 * math.pi * sqrt(h ** 3 / self.mu)

    def get_circular_alt(self, period):
        h = ((period/2/math.pi)**2 * self.mu) ** (1./3)
        return h - self.radius
