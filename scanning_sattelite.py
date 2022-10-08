import csv
import math
import unittest
from enum import Enum, auto
from math import sqrt

from consts import Body


def get_period(b: Body, alt):
    h = alt + b.radius
    return 2 * math.pi * sqrt(h ** 3 / b.mu)


Body.get_period = get_period


class MyTestCase(unittest.TestCase):
    def test_build_min_orbit(self):
        body = Body.Kerbin
        min_alt = 70
        min_alt *= 1000

        scan_min_alt = 70e3
        scan_best_alt = 250e3
        best_fov = 4

        min_fov = scan_min_alt / scan_best_alt * best_fov
        print(f"Alt: {min_alt}, period: {body.get_period(min_alt)}")


if __name__ == '__main__':
    unittest.main()

#  h=alt+r
# return 2 * math.pi * sqrt(h**3/)
