import csv
import re

experiments = {}
with open("science.cfg") as file:
    rows = list([re.split(r'\s+', v.strip()) for v in file.readlines()])
    exps = rows[0][1:]
    for e in exps:
        experiments[e] = {}
    for row in rows[1:]:
        situation = row[0]
        modes = row[1:]
        for exp, mode in zip(exps, modes):
            experiments[exp][situation] = mode
