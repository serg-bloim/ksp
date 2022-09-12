import re
from typing import Any, List

import sfsutils
from tabulate import tabulate
from addict import Dict

data = Dict(
    sfsutils.parse_savefile(r"F:\steam\steamapps\common\Kerbal Space Program\saves\UkrainianSpaseAgency\quicksave.sfs"))
ships = data.GAME.FLIGHTSTATE.VESSEL
ship_name = 'Mun-science-rover'
ships = list(sorted((s for s in ships if ship_name in s.name), key=lambda x: x.name))
print(f"Ships: {[s.name for s in ships]}")


def get_science_container_module(part):
    for m in part.MODULE:
        if m.name == 'ModuleScienceContainer':
            return m
    return None


def is_science_container(part):
    m = get_science_container_module(part)
    return m is not None and m.isEnabled == 'True'


situations = """SrfLanded
SrfSplashed
FlyingLow
FlyingHigh
InSpaceLow
InSpaceHigh""".splitlines()


class ScienceData:

    def __init__(__self, data):
        __self.__data = data
        (__self.experiement, __self.location) = data.subjectID.split('@')
        m = re.match(r'(?P<body>.*)(?P<situ>' + r'|'.join(situations) + ')(?P<biom>.*)', __self.location)
        __self.body = m.group('body')
        __self.situation = m.group('situ')
        __self.biom = m.group('biom')

    def __getattr__(self, name: str) -> Any:
        return self.__data[name]


class Report:

    def __init__(self) -> None:
        self.experiments = set()
        self.locs = set()
        self.biomes = set()
        self.situations = set()
        self.science: List[ScienceData] = []

    def post(self, science_data):
        self.experiments.add(science_data.experiement)
        self.locs.add(science_data.location)
        self.science.append(science_data)
        self.biomes.add((science_data.body, science_data.biom))
        self.situations.add(science_data.situation)

    def find(self, experiment=None, location=None, body=None, biom=None, situation=None):
        return [s for s in self.science if
                (experiment is None or s.experiement == experiment)
                and (body is None or s.body == body)
                and (location is None or s.location == location)
                and (situation is None or s.situation == situation)
                and (biom is None or s.biom == biom)]


def ensure_list(lst):
    if isinstance(lst, list):
        return lst
    else:
        return [lst]


exp_shorts = {
    'evaReport': 'eva',
    'evaScience': 'evaSci',
    'surfaceSample': 'surfSamp',
    'mysteryGoo': 'goo',
    'mobileMaterialsLab': 'materials',
    'temperatureScan': 'temp',
    'barometerScan': 'barom',
    'seismicScan': 'seism',
    'ROCScience_MunStone': 'munstone',
    'ROCScience_MunLargeCrater': 'munlcrater'
}


def print_ship_science(ship):
    science_containers = [p for p in ship.PART if is_science_container(p)]
    science_data = [ScienceData(s) for p in science_containers for s in
                    ensure_list(get_science_container_module(p).ScienceData) if s]
    rep = Report()
    for s in science_data:
        rep.post(s)

    table = []
    exps = [e for e in exp_shorts.keys() if e in rep.experiments] + [e for e in rep.experiments if e not in exp_shorts]
    for loc in sorted(rep.biomes):
        body, biom = loc
        for sit in rep.situations:
            if rep.find(body=body, biom=biom, situation=sit):
                row = [body, biom, sit]
                table.append(row)
                for exp in exps:
                    sd = rep.find(experiment=exp, body=body, biom=biom, situation=sit)
                    row.append(len(sd))
                row.append(len(rep.find(body=body, biom=biom, situation=sit)))

    exp_headers = ['body', 'biome', 'situation'] + [exp_shorts[e] if e in exp_shorts else e for e in exps] + ["Total"]
    print(f"Ship: '{ship.name}'")
    print(f"Total experiments: {len(rep.science)}")
    print(tabulate(table, headers=exp_headers))


for ship in ships:
    print_ship_science(ship)
    print()
