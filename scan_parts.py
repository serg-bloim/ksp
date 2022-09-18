import codecs
# with open(r"F:\steam\steamapps\common\Kerbal Space Program\saves\UkrainianSpaseAgency\quicksave.sfs") as file:
import os
import unittest
from math import sqrt, pi, ceil

import sfsutils
from addict import Dict
from tabulate import tabulate

# assign directory
from util import ensure_list, bits

directory = r'F:\steam\steamapps\common\Kerbal Space Program\GameData'


# iterate over files in
# that directory
def read_part_file(filename):
    with codecs.open(filename, "r", "utf-8") as file:
        all = file.read().replace('\r', '').replace("\ufeff", '')
        lines = all.split('\n')
        contents = "\n".join(line for line in (line.split("//")[0].strip() for line in lines) if len(line) > 0)
        open("temp.cfg", "w").write(contents)

    raw = sfsutils.parse_savefile(contents, sfs_is_path=False)
    return Dict(raw)


parts = []
for root, dirs, files in os.walk("parts", topdown=False):
    for name in files:
        fullfile = os.path.join(root, name)
        # print(fullfile)
        parts.append(read_part_file(fullfile))
scan_modes = [
    'AltimetryLoRes',
    'AltimetryHiRes',
    'VisualLoRes',
    'Biome',
    'Anomaly',
    'AnomalyDetail',
    'VisualHiRes',
    'ResourceLoRes',
    'ResourceHiRes',
]


class Scanner:

    def __init__(self, name, min_alt, best_alt, max_alt, fov, modes) -> None:
        self.modes = modes
        self.fov = fov
        self.max_alt = max_alt
        self.best_alt = best_alt
        self.min_alt = min_alt
        self.name = name


scanners = []
for p in parts:
    part = p.PART
    for m in ensure_list(part.MODULE):
        if m.name == 'SCANsat':
            modes = [scan_modes[m] for m in bits(int(m.sensorType))]
            scanners.append(Scanner(part.name, int(m.min_alt), int(m.best_alt), int(m.max_alt), float(m.fov), modes))


def period(alt):
    r = 60000
    mu = 1.7658000e9
    a = r + alt
    t = 2 * pi * sqrt(a * a * a / mu)
    return t


def print_ksp_timedelta(seconds):
    remainder = seconds
    remainder, secs = divmod(remainder, 60)
    remainder, mins = divmod(remainder, 60)
    days, hrs = divmod(remainder, 6)
    return f"{int(days)} days, {int(hrs)}:{int(mins)}:{round(secs, 0)}"


def calc_fov(alt, min_alt, max_alt, max_fov):
    if alt == min_alt:
        return 0.0000000001
    return max_fov * (alt - min_alt) / (max_alt - min_alt)

def total_time(alt, min_alt, max_alt, max_fov):
    revoluts = ceil(360 / calc_fov(alt, min_alt, max_alt, max_fov))
    return revoluts * period(alt)

def best_alt(min_alt, max_alt, max_fov, step=1000):
    xmin = min_alt
    fmin = 10e13
    for alt in range(min_alt, max_alt + 1, step):
        fval = total_time(alt, min_alt, max_alt, max_fov)
        if fval < fmin:
            fmin = fval
            xmin = alt
    return xmin


class MyTestCase(unittest.TestCase):
    def test1(self):
        for i in range(0, 300 + 1, 100):
            print(i)

    def test_list_best_alts_biome(self):
        biome = [s for s in scanners if "AltimetryHiRes" in s.modes]
        data = [[s.name, s.min_alt, s.best_alt, s.fov, period(s.best_alt), 360 / s.fov,
                 print_ksp_timedelta(period(s.best_alt) * 360 / s.fov), best_alt(s.min_alt, s.max_alt, s.fov)] for s in
                biome]
        print(tabulate(data, headers=['Name', 'min alt', 'Alt', 'FOV', 'Period', 'Revolutions', 'Total scan time',
                                      "Best Alt"]))

    def test_list_best_alts_res(self):
        biome = [s for s in scanners if "ResourceHiRes" in s.modes]
        data = [[s.name, s.min_alt, s.best_alt, s.fov, period(s.best_alt), 360 / s.fov,
                 print_ksp_timedelta(period(s.best_alt) * 360 / s.fov), best_alt(s.min_alt, s.max_alt, s.fov)] for s in
                biome]
        print(tabulate(data, headers=['Name', 'min alt', 'Alt', 'FOV', 'Period', 'Revolutions', 'Total scan time',
                                      "Best Alt"]))

    def test_list_all(self):
        data = []
        for s in scanners:
            row = [
                s.name,
                s.fov,
                s.min_alt,
                s.best_alt,
                s.max_alt
            ]
            data.append(row)
        print(tabulate(data, headers='name,fov,min alt,best alt,max alt'.split(',')))

    def test_best_alt(self):
        min_alt = 70
        max_alt = 250
        max_fov = 1.5

        min_alt *= 1000
        max_alt *= 1000
        bst_alt = best_alt(min_alt, max_alt, max_fov, step=100)
        print(f"""
min alt: {min_alt}
min alt: {max_alt}
bst alt: {bst_alt}
total_time(max_alt) = {print_ksp_timedelta(total_time(max_alt, min_alt, max_alt, max_fov))}
total_time(bst_alt) = {print_ksp_timedelta(total_time(bst_alt, min_alt, max_alt, max_fov))}
""")

    def test_find_best_alt(self):
        scan = next(s for s in scanners if s.name == 'scansat-multi-msi-1')

        alt = best_alt(scan.min_alt, scan.best_alt, scan.fov, 1000)
        p = period(alt)
        fov = calc_fov(alt, scan.min_alt, scan.best_alt, scan.fov)
        revoluts = int(ceil(360 / fov))
        total_time = revoluts * p
        print(f"""
        Name: {scan.name}
        Min alt: {scan.min_alt}
        Bst alt: {scan.best_alt}
        Max alt: {scan.max_alt}
        
        Alt: {alt}
        Effective fov: {round(fov, 2)}
        Period: {print_ksp_timedelta(p)}  [ {round(p, 2)} ]
        Revolutions: {revoluts}
        Total scan time: {print_ksp_timedelta(total_time)}  [ {round(total_time, 2)} ]
        """)

    def test_lower_best_alt(self):
        scan = next(s for s in scanners if s.name == 'scansat-multi-msi-1')
        data = []
        step = 10000
        for alt in range(scan.min_alt, scan.best_alt + step, step):
            p = period(alt)
            fov = calc_fov(alt, scan.min_alt, scan.best_alt, scan.fov)
            if fov == 0:
                fov = 0.00000000001
            revoluts = int(ceil(360 / fov))
            ttime = p * revoluts
            ksp_day = 6 * 60 * 60
            data.append(
                [alt, fov, revoluts, print_ksp_timedelta(p), ttime, print_ksp_timedelta(ttime)])
        print(tabulate(data, headers="Alt,Fov,Revolts,Period,Total days,Total time".split(',')))


if __name__ == '__main__':
    unittest.main()
