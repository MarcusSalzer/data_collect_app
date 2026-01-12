from pathlib import Path
from typing import Any, Literal

import polars as pl
import tomllib
from pydantic import BaseModel, ConfigDict


class DataConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")
    source_path: Path
    ignore_evts: list[str]
    min_count: int
    max_evts: int | None = None


def load_config(path: Path = Path("data_config.toml")):
    d = tomllib.loads(path.read_text())
    conf = DataConfig(**d)

    return conf


def unique_counts(df: pl.DataFrame, col: str) -> dict[Any, int]:
    return dict(df.group_by(col).agg(pl.len()).sort("len", descending=True).iter_rows())


def load_data(conf: DataConfig, verbosity: Literal[0, 1, 2] = 1):
    df = pl.read_csv(conf.source_path, try_parse_dates=True, n_rows=conf.max_evts)

    if conf.ignore_evts:
        count_pre = len(df)
        df = df.filter(pl.col("type_name").is_in(conf.ignore_evts).not_())
        if verbosity >= 1:
            print(f"[ignore_types] removed {count_pre - len(df)} records")

    # add useful columns
    df = df.with_columns(
        duration=pl.col("end_utc") - pl.col("start_utc"),
        date=pl.col("start_utc").dt.date(),
    )

    # all event types, sorted by frequency
    evt_type_counts = unique_counts(df, "type_name")

    rare_types = [k for k, c in evt_type_counts.items() if c < conf.min_count]

    df = df.with_columns(
        type_name=pl.when(pl.col("type_name").is_in(rare_types))
        .then(pl.lit("other"))
        .otherwise(pl.col("type_name"))
    )
    evt_types: list[str] = df["type_name"].unique().sort().to_list()

    if verbosity >= 1:
        print(f"loaded {len(df)} events")
        print(f"{len(evt_types) = } | {len(rare_types) = }")
    if verbosity >= 2:
        print(f"{rare_types = }")
        print(f"{evt_types = }")

    return df, evt_types


def load_subj_triples(
    path: str = "aux_data/subjective_triples.csv",
    ignore: list[str] | None = None,
):
    """Load annotated data. Can remove all triples that contain an ignored type."""
    df = pl.read_csv(
        path,
        has_header=False,
        new_columns=["anchor", "p", "n"],
    )
    if ignore is not None:
        df = df.filter(
            pl.any_horizontal(pl.col(["anchor", "p", "n"]).is_in(ignore)).not_()
        )

    return df
