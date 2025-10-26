import itertools
import random
from collections.abc import Iterable
from datetime import datetime, timedelta

import polars as pl


def extract_sequences(
    rows: Iterable[tuple[str, datetime, datetime]],
    max_gap: timedelta = timedelta(minutes=1),
    min_len: int = 1,
    verbose: bool = True,
):
    """Extract contiguous segments of events"""

    end_last: datetime | None = None

    sequences: list[list[str]] = []
    current: list[str] = []

    for typ, start, end in rows:
        if end_last is not None and start - end_last > max_gap:
            if len(current) >= min_len:
                sequences.append(current)
            current = []  # start new

        current.append(typ)  # keep building
        end_last = end

    # get the last one
    if len(current) >= min_len:
        sequences.append(current)

    if verbose:
        lens = [len(s) for s in sequences]
        lmin, lmax = min(lens), max(lens)
        lmean = sum(lens) / len(lens)
        print(
            f"extracted {len(sequences)} sequences | shortest: {lmin} | longest {lmax} | average {lmean:.2f}"
        )

    return sequences


class EvtSeqData:
    def __init__(
        self,
        df: pl.DataFrame,
        max_gap_mins: int = 10,
        blksz: int = 3,
        train_ratio: float = 0.8,
        shuffle_for_split: bool = True,
        seed: int | None = None,
        vocab: list[str] | None = None,
    ):
        seqs = extract_sequences(
            df.select("type_name", "start_utc", "end_utc").iter_rows(),
            max_gap=timedelta(minutes=max_gap_mins),
            min_len=blksz,
        )

        if vocab:
            self.vocab = vocab
        else:
            # unique labels in flattened sequences
            self.vocab = sorted(set(itertools.chain(*seqs)))

        # indexing
        self.label2idx = {k: i for i, k in enumerate(self.vocab)}
        self.blksz = blksz

        print(f"{len(self.vocab)=}")
        for s in seqs[:1]:
            print(f"example: {','.join(s)} ->", [self.label2idx[k] for k in s])

        if shuffle_for_split:
            random.seed(seed)
            random.shuffle(seqs)

        n_train = int(train_ratio * len(seqs))
        splits = {
            "train": seqs[:n_train],
            "val": seqs[n_train:],
        }
        for k in splits:
            print(f"  split {k}: {len(splits[k])} sequences")
        self.splits = splits

    def as_integers(self):
        """Get sequences for each split as a list of integers"""

        def int_map(subset: list[list[str]]):
            return [[self.label2idx[k] for k in s] for s in subset]

        return {k: int_map(self.splits[k]) for k in self.splits}
