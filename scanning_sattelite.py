import time
import unittest
from collections import deque
from itertools import count, islice
from math import ceil
from operator import itemgetter

import tabulate

from consts import Body


def calc_fov_custom(alt, radius, best_alt, best_fov):
    fov = min(alt, best_alt) / best_alt * best_fov
    fov = fov * radius / Body.Kerbin.radius
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
    time_str = f"{hrs:02}:{mins:02}:{secs:02}.{ms:.3}"
    return f"{days_str}{time_str}"


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

        print(f"Alt = {sat_alt}. ({body.get_circular_alt(sat_min_period):.3f} - {body.get_circular_alt(sat_max_period):.3f})")
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
        body = Body.Kerbin
        min_alt = 70
        min_alt *= 1000
        max_alt = 500e3

        n_iterations = 100

        scan_min_alt = 70e3
        scan_best_alt = 250e3
        scan_max_alt = 500e3

        def calc_fov(alt):
            return calc_fov_custom(alt, body.radius, scan_best_alt, best_fov)

        best_fov = 4
        angle_overlap = 0.00
        min_fov = calc_fov(scan_min_alt)
        max_fov = calc_fov(scan_max_alt)
        min_period = body.get_period(min_alt)
        print(f"Alt: {min_alt}, period: {min_period}")
        min_period_equator_angle = min_period / body.axisperiod * 360
        max_k = int(360 // min_period_equator_angle)
        orbits = []
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
                    if sat_alt < scan_min_alt:
                        # print(f"Alt is low. k = {k}, n = {n}, t = {t}. alt = {sat_alt} < min_alt ({scan_min_alt})")
                        continue
                    if sat_alt > max_alt:
                        # print(f"Alt is too high. k = {k}, n = {n}, t = {t}. alt = {sat_alt} > max_alt ({max_alt})")
                        break
                    fov = calc_fov(sat_alt)
                    overlap = fov - (sat_revolution_angle_shift / n)
                    total_scan_time = (n * k + n - t) * sat_period
                    # print(f"Alt = {print_alt(sat_alt)} Total scan time = {print_period(total_scan_time)}")
                    orbits.append((total_scan_time, k, n, t))
            pass
        print(f"Got {len(orbits)} orbits")
        orbits.sort(key=itemgetter(0))
        data = []
        for o in orbits[:100]:
            total_scan_time, k, n, t = o
            angle_resolution = 360 / (k * n + n - t)
            sat_revolution_angle_shift = angle_resolution * n
            sat_period = body.axisperiod * sat_revolution_angle_shift / 360
            sat_alt = body.get_circular_alt(sat_period)
            fov = calc_fov(sat_alt)
            overlap = fov - (sat_revolution_angle_shift / n)
            period_precision = sat_period * overlap / sat_revolution_angle_shift / n
            data.append([print_alt(sat_alt), print_period(total_scan_time), print_period(sat_period), fov, overlap,
                         period_precision, k, n, t])
        print(tabulate.tabulate(data, headers="Alt,Scan time,Period,fov,a_precision,p_precision,k,n,t".split(",")))
        # min_n =
        # for n in range()


if __name__ == '__main__':
    unittest.main()

#  h=alt+r
# return 2 * math.pi * sqrt(h**3/)
