import time
import unittest
from collections import deque
from itertools import count, islice
from math import ceil
from operator import itemgetter

import tabulate

from consts import Body, Scanner


def calc_fov_custom(alt, radius, best_alt, best_fov):
    fov = min(alt, best_alt) / best_alt * best_fov
    fov = fov * Body.Kerbin.radius / radius
    fov = min(fov, 20)
    return fov


def print_alt(alt, precision=3):
    alt = round(alt, precision)
    return f"{alt:,}"


def print_period(time_secs):
    secs = int(time_secs)
    ms = time_secs - secs
    mins, secs = divmod(secs, 60)
    hrs, mins = divmod(mins, 60)
    days, hrs = divmod(hrs, 6)
    days_str = "" if days == 0 else f"{int(days)}d "
    time_str = f"{hrs:02}:{mins:02}:{secs:02}.{ms:.3f}"
    return f"{days_str}{time_str}"


def sat_orbits_gen(body, min_alt, max_alt, scan_best_alt, best_fov, angle_overlap=0.0, n_iterations=100):
    def calc_fov(alt):
        return calc_fov_custom(alt, body.radius, scan_best_alt, best_fov)

    min_fov = calc_fov(min_alt)
    max_fov = calc_fov(max_alt)
    min_period = body.get_period(min_alt)
    min_period_equator_angle = min_period / body.axisperiod * 360
    max_k = int(360 // min_period_equator_angle)
    for k in range(max_k, -1, -1):
        min_angle = 360 / (k + 1)
        max_angle = 360 if k == 0 else 360 / k
        min_period = min_angle / 360 * body.axisperiod
        alt = body.get_circular_alt(min_period)
        fov = calc_fov(alt) - angle_overlap
        min_n = int(ceil(max_angle / fov))
        for n in range(1, min_n + n_iterations):
            # test if this n privides full coverage without gaps:
            t = 1
            if k == 0 and n == 1:
                continue
            angle_resolution = 360 / (k * n + n - t)
            sat_revolution_angle_shift = angle_resolution * n
            sat_period = body.axisperiod * sat_revolution_angle_shift / 360
            sat_alt = body.get_circular_alt(sat_period)
            fov = calc_fov(sat_alt)
            if angle_resolution - fov > angle_overlap:
                continue  # this n value doesn't provide a sufficient gap coverage
            for t in range(1, n):
                intersections = [0] * n
                for x in range(n):
                    intersect = (x * t) % n
                    intersections[intersect] += 1
                if any(x == 0 for x in intersections):
                    # print(f"RESONANT. k = {k}, n = {n}, t = {t}. Intersections = {intersections}")
                    break
                angle_resolution = 360 / (k * n + n - t)
                # 1 satellite revolution shifts this much of an equatorial angle
                sat_revolution_angle_shift = angle_resolution * n
                sat_period = body.axisperiod * sat_revolution_angle_shift / 360
                sat_alt = body.get_circular_alt(sat_period)
                if sat_alt < min_alt:
                    # print(f"Alt is low. k = {k}, n = {n}, t = {t}. alt = {sat_alt} < min_alt ({scan_min_alt})")
                    continue
                if sat_alt > max_alt:
                    # print(f"Alt is too high. k = {k}, n = {n}, t = {t}. alt = {sat_alt} > max_alt ({max_alt})")
                    break
                fov = calc_fov(sat_alt)
                overlap = fov - (sat_revolution_angle_shift / n)
                total_scan_time = (n * k + n - t) * sat_period
                # print(f"Alt = {print_alt(sat_alt)} Total scan time = {print_period(total_scan_time)}")
                yield total_scan_time, k, n, t


def calc_precision_factors(precision, n, t):
    nxt = 1
    prv = 0
    for i in range(n):
        x = i * t % n
        if x == 1:
            nxt = i
        if x == n - 1:
            prv = i
    return -precision / prv, precision / nxt


class OrbitDesctiption:
    angle_resolution: float
    alt: float
    max_alt: float
    min_alt: float
    max_period: float
    min_period: float
    fov: float
    period: float
    full_scan_period: float
    angle_phase: float
    k: int
    n: int
    t: int


def describe_orbit(body, k, n, t, scanner):
    angle_resolution = 360 / (k * n + n - t)
    sat_revolution_angle_shift = angle_resolution * n
    sat_period = body.axisperiod * sat_revolution_angle_shift / 360
    sat_alt = body.get_circular_alt(sat_period)
    fov = calc_fov_custom(sat_alt, body.radius, scanner.best, scanner.fov)
    std_angle_precision = fov - angle_resolution
    std_period_precision = std_angle_precision / sat_revolution_angle_shift * sat_period / (k + 1)
    angle_precision_neg, angle_precision_pos = calc_precision_factors(std_angle_precision, n, t)
    period_precision_neg, period_precision_pos = calc_precision_factors(std_period_precision, n, t)
    sat_min_period = sat_period + period_precision_neg
    sat_max_period = sat_period + period_precision_pos
    od = OrbitDesctiption()
    od.angle_resolution = angle_resolution
    od.angle_phase = sat_revolution_angle_shift
    od.period = sat_period
    od.fov = fov
    od.min_period = sat_min_period
    od.max_period = sat_max_period
    od.min_alt = body.get_circular_alt(sat_min_period)
    od.max_alt = body.get_circular_alt(sat_max_period)
    od.alt = body.get_circular_alt(sat_period)
    od.full_scan_period = (n * k + n - t) * sat_period
    od.k = k
    od.n = n
    od.t = t
    return od


def find_best_orbit(body, scanner: Scanner, min_alt, max_alt, angle_overlap=0.0):
    orbits = list(sat_orbits_gen(body, min_alt, max_alt, scanner.best, scanner.fov, angle_overlap))
    orbits.sort(key=itemgetter(0))
    if orbits:
        o = orbits[0]
        total_scan_time, k, n, t = o
        return describe_orbit(body, k, n, t, scanner)


class MyTestCase(unittest.TestCase):
    def test_simulate_orbit(self):
        body = Body.Kerbin
        best_fov = 4
        scan_best_alt = 250e3
        k = 7
        n = 12
        t = 1

        period_error = 0

        # period_error = -0.144

        def calc_fov(alt):
            return calc_fov_custom(alt, body.radius, scan_best_alt, best_fov)

        ideal_angle_resolution = 360 / (k * n + n - t)
        ideal_sat_revolution_angle_shift = ideal_angle_resolution * n
        ideal_sat_period = body.axisperiod * ideal_sat_revolution_angle_shift / 360
        ideal_sat_alt = body.get_circular_alt(ideal_sat_period)
        ideal_fov = calc_fov(ideal_sat_alt)
        std_angle_precision = ideal_fov - ideal_angle_resolution
        angle_precision_neg, angle_precision_pos = calc_precision_factors(std_angle_precision, n, t)
        period_precision_neg = angle_precision_neg / ideal_sat_revolution_angle_shift * ideal_sat_period / (k + 1)
        period_precision_pos = angle_precision_pos / ideal_sat_revolution_angle_shift * ideal_sat_period / (k + 1)
        sat_min_period = ideal_sat_period + period_precision_neg
        sat_max_period = ideal_sat_period + period_precision_pos
        sat_period = ideal_sat_period + period_error
        sat_revolution_angle_shift = sat_period / body.axisperiod * 360
        angle_resolution = sat_revolution_angle_shift / n
        sat_alt = body.get_circular_alt(sat_period)
        fov = calc_fov(sat_alt)

        print(
            f"Alt = {sat_alt}. ({body.get_circular_alt(sat_min_period):.3f} - {body.get_circular_alt(sat_max_period):.3f})")
        print(f"Period = {sat_period}. ({sat_min_period :.3f} - {sat_max_period :.3f})")
        print(f"Fov = {fov}.")
        print(f"Angle precision: {angle_precision_neg} : {angle_precision_pos}")
        print(f"Period precision: {period_precision_neg} : {period_precision_pos}")

        print(f"Phase angle = {angle_resolution}")
        print(f"sat_revolution_angle_shift = {sat_revolution_angle_shift}")

        def equator_intersection_gen():
            for i in count():
                angle = sat_revolution_angle_shift * i
                yield angle % 360

        coverage = deque([(-22, -21), (381, 382)])
        timestamp = 0
        visited_angles = set()
        for angle in islice(equator_intersection_gen(), k * n + n - t):
            a2 = round(angle, 2)
            if a2 in visited_angles:
                print(f"Visiting {a2:.2f} second time")
            visited_angles.add(a2)
            lo = angle - fov / 2
            hi = angle + fov / 2
            angle_overlap = -1
            for i in range(1, len(coverage)):
                nlo, nhi = coverage[i]
                plo, phi = coverage[i - 1]
                if lo < nlo and hi > phi:  # insert here
                    if lo <= phi:  # need to merge with previous
                        angle_overlap = phi - lo
                        lo = plo
                    if hi >= nlo:
                        angle_overlap = min(angle_overlap, hi - nlo)
                        hi = nhi
                    coverage.insert(i, (lo, hi))
                    if lo == plo:
                        coverage.remove((plo, phi))
                    if hi == nhi:
                        coverage.remove((nlo, nhi))

                    break
            timestamp += sat_period
            # print(f"{print_period(timestamp):16} {round(angle, 2):6.2f} - {angle_overlap:5.2f} - {len(coverage):2} - {[(round(a, 1), round(b, 1)) for (a, b) in coverage]}")
        print(list(coverage))
        time.sleep(0.1)
        pass

    def test_build_min_orbit(self):
        body = Body.Mun
        scanner = Scanner.VS_3
        scan_min_alt = scanner.min
        scan_best_alt = scanner.best
        scan_max_alt = scanner.max
        best_fov = scanner.fov

        angle_overlap = 0.00
        min_alt = 100e3
        min_alt = max(min_alt, scan_min_alt)
        max_alt = 500e3
        max_alt = min(max_alt, scan_max_alt)
        orbits = list(sat_orbits_gen(body, min_alt, max_alt, scan_best_alt, best_fov, angle_overlap))
        print(f"{scanner.name} @ {body.name}")
        print(f"FOV     : {best_fov}")
        print(f"Min alt : {min_alt}")
        print(f"Best alt: {scan_best_alt}")
        print(f"Max alt : {scan_max_alt}")
        print(f"Got {len(orbits)} orbits")
        orbits.sort(key=itemgetter(0))
        data = []
        for o in orbits[:100]:
            total_scan_time, k, n, t = o
            orb = describe_orbit(body, k, n, t, scanner)
            data.append(
                [print_period(total_scan_time),
                 print_alt(orb.alt),
                 print_alt(orb.min_alt),
                 print_alt(orb.max_alt),
                 print_period(orb.period),
                 orb.fov,
                 print_period(orb.min_period),
                 print_period(orb.max_period),
                 k, n, t])
        print(tabulate.tabulate(data,
                                headers="Scan time,Alt,Min alt,max alt,Period,fov,min_period,max_period,k,n,t".split(
                                    ",")))

    def test_miltiple_scanners(self):
        body = Body.Minmus
        scanners = [Scanner.VS_11, Scanner.R_3B_Radar, Scanner.R_EO_1_Radar, Scanner.SAR_X,
                    Scanner.SCAN_R2]
        min_alt = 140.5e3
        max_alt = 150e3
        print(f"Scanners for {body.name}")
        data = []
        for s in scanners:
            orb = find_best_orbit(body, s, max(min_alt, s.min), min(max_alt, s.max))
            if orb:
                data.append(
                    [s.name, print_period(orb.full_scan_period), print_alt(orb.alt), orb.k, orb.n, orb.t, orb.fov,
                     print_alt(orb.min_alt), print_alt(orb.max_alt)])
            else:
                data.append([s.name, "---"])
        print(tabulate.tabulate(data, headers="Name,period,Alt,K,N,T,FOV,Min alt,Max alt".split(",")))

    def test_simulate_miltiple_scanners(self):
        body = Body.Minmus
        k, n, t = 2, 15, 1
        scanners = [Scanner.VS_11, Scanner.R_3B_Radar, Scanner.R_EO_1_Radar, Scanner.SAR_X, Scanner.SAR_L,
                    Scanner.SCAN_R, Scanner.SCAN_R2, Scanner.SCAN_RX,Scanner.Narrow_band_scanner]
        orb = describe_orbit(body, k, n, t, Scanner.SAR_X)
        min_alt = orb.alt
        max_alt = orb.alt
        print(f"Scanners for {body.name}")
        data = []
        for s in scanners:
            ord = find_best_orbit(body, s, max(min_alt, s.min), min(max_alt, s.max))
            if ord:
                data.append([s.name, print_period(ord.full_scan_period), print_alt(ord.alt), ord.k, ord.n, ord.t])
        print(tabulate.tabulate(data, headers="Name,period,Alt,K,N,T".split(",")))


if __name__ == '__main__':
    unittest.main()

#  h=alt+r
# return 2 * math.pi * sqrt(h**3/)
