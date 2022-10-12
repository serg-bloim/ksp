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
        h = ((period / 2 / math.pi) ** 2 * self.mu) ** (1. / 3)
        return h - self.radius


class Scanner(Enum):
    Narrow_band_scanner = (2, 10, 150, 500, False)
    M700_Survery_scanner = (3, 15, 500, 7500, False)
    MS_1 = (3, 20, 70, 250, True)
    MS_2A = (4, 100, 500, 750, True)
    MS_R = (1.5, 70, 300, 400, True)
    R_3B_Radar = (1.5, 5, 70, 250, False)
    R_EO_1_Radar = (3.5, 50, 100, 500, False)
    SAR_C = (3, 500, 700, 750, False)
    SAR_L = (4, 250, 500, 1000, False)
    SAR_X = (1.5, 70, 250, 500, False)
    SCAN_R = (1, 20, 70, 250, True)
    SCAN_R2 = (2.5, 70, 250, 500, True)
    SCAN_RX = (3, 100, 500, 750, True)
    VS_1 = (1.5, 20, 70, 250, True)
    VS_11 = (4, 100, 200, 1000, True)
    VS_3 = (2.5, 70, 350, 500, True)

    def __init__(self, fov, min, best, max, require_daytime) -> None:
        self.fov = fov
        self.min = min * 1000
        self.best = best * 1000
        self.max = max * 1000
        self.require_daytime = require_daytime

    def get_period(self, alt):
        h = alt + self.radius
        return 2 * math.pi * sqrt(h ** 3 / self.mu)

    def get_circular_alt(self, period):
        h = ((period / 2 / math.pi) ** 2 * self.mu) ** (1. / 3)
        return h - self.radius
