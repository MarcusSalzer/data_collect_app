from io import StringIO
from pathlib import Path

import polars as pl
import polars.selectors as cs
import regex as re


def tz_local_to_utc(df: pl.DataFrame, tz="Europe/Stockholm", cols=("start", "end")):
    """Assume local (naive) datetimes, assign tz and get utc"""
    new = df.with_columns(pl.col(cols).dt.replace_time_zone(tz))
    new = new.with_columns(
        pl.col(c).dt.convert_time_zone("UTC").alias(f"{c}_utc") for c in cols
    )
    new = new.with_columns(
        (pl.col(c).dt.base_utc_offset() + pl.col(c).dt.dst_offset())
        .dt.total_seconds()
        .alias(f"{c}_offset_s")
        for c in cols
    )
    return new


def to_new_app_schema(df: pl.DataFrame):
    df = df.select(
        pl.col("id"),
        pl.col("name").str.strip_chars().alias("type_name"),
        pl.col("start_utc"),
        pl.col("start_offset_s"),
        pl.col("end_utc"),
        pl.col("end_offset_s"),
    )
    # format all datetime columns
    df = df.with_columns(cs.datetime().dt.strftime("%Y-%m-%dT%H:%M:%SZ"))
    return df


if __name__ == "__main__":
    SAVEDIR = Path("data/out")
    SAVEDIR.mkdir(exist_ok=True)

    files = list(Path("data").glob("*.csv"))

    csv = files[0].read_text("utf-8")
    # remove extra spaces
    csv = re.sub(r" *, *", ",", csv)

    df = pl.read_csv(
        StringIO(csv),
        schema={
            "id": pl.UInt32,
            "name": pl.String,
            "start": pl.Datetime,
            "end": pl.Datetime,
        },
        try_parse_dates=True,
        null_values=["null"],
    )

    print(df.tail(6))
    new = tz_local_to_utc(df)
    # print(new.tail(6))
    new = to_new_app_schema(new)
    print(new.tail(6))
    new.write_csv(SAVEDIR / "fix.csv")
