# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.

from PIL import Image
from collections import Counter
import matplotlib.cm as cm
from fontTools.merge import cmap
from matplotlib.colors import Normalize

# img = Image.open(r"F:\steam\steamapps\common\Kerbal Space Program\GameData\SCANsat\PluginData\Mun_biome_962x481.png")
img = Image.open(r"F:\steam\steamapps\common\Kerbal Space Program\GameData\SCANsat\PluginData\Mun_biome_5000x2500.png")
pixel_map = img.getdata()
window_size = 50
(w, h) = img.size
filter = img.copy()
filter_pm = filter.load()


def windowed_coords(x0, y0, wx=0, wy=0):
    dx = wx - window_size // 2
    dy = wy - window_size // 2
    x = (x0 + dx) % w
    y = (y0 + dy) % h
    return y * w + x


filter_data = [0] * len(pixel_map)
for y in range(h):
    print(y)
    pixels = (pixel_map[windowed_coords(-1, y, wx, wy)]
              for wx in range(window_size)
              for wy in range(window_size))
    window = Counter(pixels)
    for x in range(w):
        chunk_remove = (pixel_map[windowed_coords(x - 1, y, 0, wy)]
                        for wy in range(window_size))
        for i in chunk_remove:
            if window[i] > 1:
                window[i] -= 1
            else:
                del window[i]
        chunk_add = (pixel_map[windowed_coords(x, y, window_size, wy)]
                        for wy in range(window_size))
        for i in chunk_add:
            window[i] += 1

        filter_data[windowed_coords(x, y)] = len(window)

cmap = cm.plasma
norm = Normalize(vmin=1, vmax=max(filter_data))
print("new_data")
new_data = [cmap(norm(lvl), bytes=True) for lvl in filter_data]
print("filter.putdata")
filter.putdata(new_data)
filter.show()