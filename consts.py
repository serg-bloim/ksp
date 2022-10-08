import csv
from enum import Enum, auto

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
