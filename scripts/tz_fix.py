from io import StringIO
from pathlib import Path
import polars as pl


def tz_local_to_utc(df: pl.DataFrame, tz="Europe/Stockholm", cols=("start", "end")):
    """Assume local (naive) datetimes, assign tz and get utc"""
    new = df.with_columns(pl.col(cols).dt.replace_time_zone(tz))
    new = new.with_columns(
        pl.col(c).dt.convert_time_zone("UTC").alias(f"{c}_utc") for c in cols
    )
    new = new.with_columns(
        (pl.col(c).dt.base_utc_offset() + pl.col(c).dt.dst_offset())
        .dt.total_seconds()
        .alias(f"{c}_offset")
        for c in cols
    )
    return new


if __name__ == "__main__":
    SAVEDIR = Path("data/out")
    SAVEDIR.mkdir(exist_ok=True)

    files = list(Path("data").glob("*.csv"))

    csv = files[0].read_text("utf-8").replace(", ", ",")

    df = pl.read_csv(
        StringIO(csv),
        try_parse_dates=True,
    )

    print(df)
    new = tz_local_to_utc(df)
    print(new)
    new.write_csv(SAVEDIR / "fix.csv")
