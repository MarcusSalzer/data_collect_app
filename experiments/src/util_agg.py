from collections.abc import Sequence
from datetime import timedelta

import polars as pl


def agg_duration_per_day(df: pl.DataFrame, k_top: int = 3):
    """Aggregate by:

    - group_by(date)
    - iter_rows
    - dict-counter

    returns
    -------

    df_agg: DataFrame
        seconds per day, one column per event type
    df_topk: DataFrame
        top k most common events per day
    """

    expect_cols = {"date", "type_name", "duration"}
    assert expect_cols.issubset(df.columns), (
        f"{expect_cols=}, missing: {expect_cols.difference(df.columns)}"
    )

    evt_types = df["type_name"].unique().sort().to_list()
    per_day = (
        df.group_by("date")
        .agg("type_name", pl.col("duration").dt.total_seconds())
        .sort("date")
    )

    topks: list[list[str]] = []
    daily_sums = []

    # do each day
    for d, types, durs in per_day.iter_rows():
        sums = dict.fromkeys(evt_types, 0)
        # all events this day
        for ty, du in zip(types, durs, strict=True):
            sums[ty] += du

        daily_sums.append([d] + list(sums.values()))
        topks.append(sorted(sums.keys(), key=lambda k: -sums[k])[:k_top])

    df_agg = pl.DataFrame(daily_sums, schema=["date"] + evt_types, orient="row")
    # sort cols alpha
    df_agg = df_agg.select(["date"] + sorted(evt_types))

    # keep topK activities per day
    df_topk = per_day.select("date").with_columns(pl.Series("topk", topks))

    return df_agg, df_topk


def agg_duration_per_day_optimized(df: pl.DataFrame, k_top: int = 3):
    """Aggregate..."""

    expect_cols = {"date", "type_name", "duration"}
    assert expect_cols.issubset(df.columns), (
        f"{expect_cols=}, missing: {expect_cols.difference(df.columns)}"
    )

    evt_types = df["type_name"].unique().sort().to_list()

    # aggregate durations per (date, type_name)
    agg = (
        df.with_columns(pl.col("duration").dt.total_seconds())
        .group_by(["date", "type_name"])
        .agg(pl.sum("duration").alias("duration_sum"))
    )

    # pivot into a (date*event_type) wide table
    pivot = agg.pivot(
        values="duration_sum",
        index="date",
        on="type_name",
        aggregate_function="first",  # already aggregated
    ).sort("date")

    # order cols and fill empty
    pivot = pivot.select(["date"] + evt_types).sort("date").fill_null(0)

    # X_eff = pivot.select(evt_types).to_numpy()  # exclude date column


def agg_durations_periodic(
    df_agg: pl.DataFrame,
    evt_types: Sequence[str],
    period: timedelta = timedelta(weeks=4),
):
    df_agg_p = df_agg.group_by_dynamic("date", every=period, start_by="monday").agg(
        pl.col(c).sum() for c in evt_types
    )

    return df_agg_p


def add_week_calendar_cols(df_agg: pl.DataFrame):
    wd_names = ("mon", "tue", "wed", "thu", "fri", "sat", "sun")
    df_cal = df_agg.select(
        date=df_agg["date"],
        year=df_agg["date"].dt.year(),
        week=df_agg["date"].dt.week(),
        wd=df_agg["date"].dt.weekday(),
    ).with_columns(
        wd_name=(pl.col("wd") - 1).map_elements(
            lambda i: wd_names[i], return_dtype=pl.String
        ),
        day_num=pl.col("date").dt.day(),
    )
    return df_cal
