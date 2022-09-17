import codecs
import shutil

import sfsutils
from tabulate import tabulate
from addict import Dict

# with open(r"F:\steam\steamapps\common\Kerbal Space Program\saves\UkrainianSpaseAgency\quicksave.sfs") as file:
import os

# assign directory
directory = r'F:\steam\steamapps\common\Kerbal Space Program\GameData'

# iterate over files in
# that directory
def read_part_file(filename):
    with codecs.open(filename, "r", "utf-8") as file:
        all = file.read()
        lines = all.split('\r\n')
        contents = "\n".join(line.lstrip() for line in lines)

    raw = sfsutils.parse_savefile(contents, sfs_is_path=False)
    return Dict(raw)

parts=[]
for moddir in os.listdir(directory):
        parts_dir = os.path.join(directory, moddir, "Parts")
        # checking if it is a file
        if os.path.isdir(parts_dir):
            for part_dir in os.listdir(parts_dir):
                part_path = os.path.join(parts_dir, part_dir)
                if os.path.isdir(part_path):
                    for part_file in os.listdir(part_path):
                        ppath = os.path.join(part_path, part_file)
                        if os.path.isfile(ppath) and os.path.splitext(ppath)[1] == '.cfg':
                            lpath = os.path.join("parts", moddir, part_dir)
                            os.makedirs(lpath, exist_ok=True)
                            shutil.copy(ppath, lpath)


for p in parts:
    print(f"{p.PART.module} / {p.PART.name}")
    if p.PART.module != "Part":
        pass