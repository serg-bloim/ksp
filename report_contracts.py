import unittest
from collections import defaultdict
from typing import Any, List

import sfsutils
from addict import Dict

from utils import ensure_list

data = Dict(
    sfsutils.parse_savefile(r"F:\steam\steamapps\common\Kerbal Space Program\saves\UkrainianSpaseAgency\quicksave.sfs"))

def get_scenario(name):
    for s in data.GAME.SCENARIO:
        if s.name == name:
            return s

def get_mission_contracts(missionName):
    scenario = get_scenario("contractScenario")
    mission = [m for m in ensure_list(scenario.Contracts_Window_Parameters.Contracts_Window_Mission) if m.MissionName == missionName][0]
    contract_guids = [row.split("|")[0] for row in mission.ActiveListID.split(",")]
    cs = get_scenario("ContractSystem").CONTRACTS.CONTRACT
    return [c for c in cs if c.guid in contract_guids]


class ContractExperiment:

    def __init__(self, contract, experiment, body, biome, situation) -> None:
        self.contract = contract
        self.experiments = experiment
        self.body = body
        self.biome = biome
        self.situation = situation


class MyTestCase(unittest.TestCase):
    def test_list_kerbin_contracts(self):
        cs = get_mission_contracts("Kerbin")
        print(f"Found {len(cs)} contracts:")
        exps = []
        for c in cs:
            params = ensure_list(c.PARAM)
            completed = sum(1 for p in params if p.state == 'Complete')
            print(f" - {c.title} ({completed}/{len(params)})")
            for p in ensure_list(c.PARAM):
                if p.id == 'CollectScience' and p.name == 'CollectScienceCustom':
                    exps.append(ContractExperiment(c, ensure_list(p.experiment), p.targetBody, p.biome, p.situation))

        biomes: defaultdict[Any, List[ContractExperiment]] = defaultdict(list)
        experiments: defaultdict[Any, List[ContractExperiment]] = defaultdict(list)
        for e in exps:
            biomes[e.biome].append(e)

            for ee in e.experiments:
                experiments[ee].append(e)

        print()
        print("Biomes:")
        for b,exps in biomes.items():
            print("Biome "+ b)
            sits = set(e.situation for e in exps)
            for s in sits:
                print(f" - {s}:")
                for e in exps:
                    if e.situation == s:
                        for ee in e.experiments:
                            print(f"   - {ee} : {e.contract.title}")

        print()
        print("Experiments:")
        for e,exps in experiments.items():
            print("Experiment "+ e)
            for e in exps:
                print(f" - {e.contract.title} ({e.situation})")


if __name__ == '__main__':
    unittest.main()
