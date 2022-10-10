import unittest
from itertools import count

from consts import Body
from scanning_sattelite import calc_fov_custom


class MyTestCase(unittest.TestCase):
    def test_something(self):
        import matplotlib.pyplot as plt
        import matplotlib.patches as patches
        from PIL import Image
        im = Image.new("RGB", (500,500), (255,255,255))
        # Create figure and axes
        fig, ax = plt.subplots()
        # Display the image
        ax.imshow(im)
        # Create a Rectangle patch
        rect = patches.Rectangle((50, 100), 40, 30, linewidth=1, edgecolor='r', facecolor='none')
        # Add the patch to the Axes
        ax.add_patch(rect)
        plt.show()


if __name__ == '__main__':
    unittest.main()


def angle_gen(phase, fov):
    body = Body.Kerbin
    best_fov = 4
    scan_best_alt = 250e3
    k = 7
    n = 13
    t = 1
    period_error = 3.5

    def calc_fov(alt):
        return calc_fov_custom(alt, body.radius, scan_best_alt, best_fov)

    ideal_angle_resolution = 360 / (k * n + n - t)
    ideal_sat_revolution_angle_shift = ideal_angle_resolution * n
    ideal_sat_period = body.axisperiod * ideal_sat_revolution_angle_shift / 360
    sat_period = ideal_sat_period + period_error
    sat_revolution_angle_shift = sat_period / body.axisperiod * 360
    angle_resolution = sat_revolution_angle_shift / n
    sat_alt = body.get_circular_alt(sat_period)
    fov = calc_fov(sat_alt)

    print(f"Alt = {sat_alt}.")
    print(f"Period = {sat_period}.")
    print(f"Fov = {fov}.")
    print(f"Phase angle = {angle_resolution}")
    print(f"sat_revolution_angle_shift = {sat_revolution_angle_shift}")

    def equator_intersection_gen():
        for i in count():
            angle = sat_revolution_angle_shift * i
            yield angle % 360
    return equator_intersection_gen()