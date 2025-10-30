"""
Manually annotate similarity in triples of events.
"""

import math
import random
import sys
from pathlib import Path

import polars as pl
from rich.console import Console

cons = Console()

sys.path.append("src")

import data_util

MIN_COUNT = 100
MAX_ITER = 50

triples_file = Path("aux_data/subjective_triples.csv")
skips_file = Path("aux_data/subjective_triples_skips.csv")
triples_file.parent.mkdir(parents=True, exist_ok=True)
if triples_file.exists():
    triples = set(pl.read_csv(triples_file, has_header=False).iter_rows())
else:
    triples = set()

if skips_file.exists():
    skips = set(pl.read_csv(skips_file, has_header=False).iter_rows())
else:
    skips = set()


data_conf = data_util.load_config()
data_conf.min_count = MIN_COUNT
_, evt_types = data_util.load_data(data_conf, verbosity=1)
evt_types.remove("other")

n_possible = math.comb(len(evt_types), 3)

print(f"has {len(triples)} triples | has {len(skips)} skips ")
print(f"{(len(triples) + len(skips)) / n_possible:.2%} done")


for _ in range(MAX_ITER):
    anchor, a, b = random.sample(evt_types, k=3)

    # skip already done
    if (anchor, a, b) in triples or (anchor, b, a) in triples:
        continue
    if (anchor, min(a, b), max(a, b)) in skips:
        continue

    cons.print(f"\n[b]{anchor}[/b] [dim]is most similar to?[/dim]")
    r = cons.input(f"  a) [b]{a}[/b]  b) [b]{b}[/b] ? [dim](enter to skip)[/dim] ")
    if r == "a":
        new = (anchor, a, b)
    elif r == "b":
        new = (anchor, b, a)
    elif r == "":
        skips.add((anchor, min(a, b), max(a, b)))
        continue
    else:
        print("stop!")
        break

    triples.add(new)


with skips_file.open("w") as f:
    for anchor, a, b in sorted(skips):
        f.write(f"{anchor},{a},{b}\n")

with triples_file.open("w") as f:
    for anchor, p, n in sorted(triples):
        f.write(f"{anchor},{p},{n}\n")
cons.print(f"[blue]Saved new {triples_file}![/blue]")
