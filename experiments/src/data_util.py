from pathlib import Path
from typing import Any

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
    return DataConfig(**d)


def unique_counts(df: pl.DataFrame, col: str) -> dict[Any, int]:
    return dict(df.group_by(col).agg(pl.len()).sort("len", descending=True).iter_rows())


def load_data(conf: DataConfig):
    df = pl.read_csv(conf.source_path, try_parse_dates=True, n_rows=conf.max_evts)

    if conf.ignore_evts:
        count_pre = len(df)
        df = df.filter(pl.col("type_name").is_in(conf.ignore_evts).not_())
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
    evt_types = df["type_name"].unique().sort().to_list()

    print(f"loaded {len(df)} events")
    print(f"{len(rare_types) = } | {rare_types = }")
    print(f"{len(evt_types) = } | {evt_types = }")

    return df, evt_types
