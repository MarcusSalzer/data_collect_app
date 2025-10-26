from collections.abc import Sequence

import numpy as np
import polars as pl
from plotly import graph_objects as go
from plotly import io as pio
from sklearn.preprocessing import StandardScaler


def set_plotly_template(
    base_template="plotly_dark",
    auto_size=False,
    w: int = 600,
    h: int = 300,
    transparent_background=True,
    margin=40,
):
    """Some kind of plot template"""
    plot_temp = pio.templates[base_template]
    assert isinstance(plot_temp, go.layout.Template)
    assert isinstance(plot_temp.layout, go.Layout)
    plot_temp.layout.margin = dict.fromkeys(["t", "l", "r", "b"], margin)

    if not auto_size:
        plot_temp.layout.width = w
        plot_temp.layout.height = h
        plot_temp.layout.autosize = False
    if transparent_background:
        plot_temp.layout.paper_bgcolor = "rgba(0,0,0,0)"
        plot_temp.layout.plot_bgcolor = "rgba(0,0,0,0)"
    pio.templates.default = plot_temp


def weeks_cal_grid(
    df_cal: pl.DataFrame,
    df_topk: pl.DataFrame,
    width: int = 200,
    filter_expr: pl.Expr | None = None,
):
    """Plot a calendar grid. NOTE: slow"""
    if filter_expr is not None:
        df_cal = df_cal.filter(filter_expr)
        df_topk = df_topk.filter(filter_expr)

    assert len(df_cal["year"].unique()) == 1, "only works in a year now?"

    fig = go.Figure()
    df_cal = df_cal.with_columns(
        hovertext=(
            df_cal["wd_name"]
            + " "
            + df_cal["date"]
            + ": "
            + df_topk["topk"].list.join(", ")
        )
    )
    # Add rectangles (calendar cells)
    for r in df_cal.iter_rows(named=True):
        fig.add_shape(
            type="rect",
            x0=r["wd"] - 0.5,
            x1=r["wd"] + 0.5,
            y0=r["week"] - 0.5,
            y1=r["week"] + 0.5,
            line=dict(color="black", width=1),
            fillcolor=r["color"],
        )

    # Add hover info
    fig.add_trace(
        go.Scatter(
            hovertext=df_cal["hovertext"],
            x=df_cal["wd"],
            y=df_cal["week"],
            text=df_cal["day_num"],
            mode="text",
            textfont=dict(size=20, color="red"),
            hoverinfo="text",
        )
    )
    weeks = sorted(df_cal["week"].unique())

    aspect_ratio = len(weeks) / 7

    # Layout
    fig.update_yaxes(
        autorange="reversed",
        tickvals=weeks,
        title="Week",
        showgrid=False,
    )
    fig.update_xaxes(
        tickvals=list(range(1, 8)),
        ticktext=["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        title="Weekday",
        showgrid=False,
    )
    fig.update_layout(
        width=width,
        height=aspect_ratio * width + 20,
        plot_bgcolor="rgba(0,0,0,0)",
        margin=dict(l=0, r=0, t=0, b=0),
    )

    return fig


def vecs2color(X: np.ndarray):
    """Create a list of rgb colors from a matrix"""

    assert X.ndim == 2, "expects 2d array"
    assert X.shape[1] == 3, "expects last dim to have size 3"

    # normalize
    mi, ma = X.min(), X.max()
    X = (X - mi) / (ma - mi)

    # quantize
    X = (X * 255).astype(np.int16)
    return [f"rgb({v[0]},{v[1]},{v[2]})" for v in X]


def scatter_embs(
    X: np.ndarray,
    texts: Sequence[str] | None,
    normalize_std=True,
):
    """Plot first two dimensions in xy-plane, all three dimensions to color."""
    assert X.shape[-1] == 3, "expects 3 dim embs"

    if normalize_std:
        X = StandardScaler().fit_transform(X)

    fig = go.Figure(
        go.Scatter(
            x=X[:, 0],
            y=X[:, 1],
            mode="markers",
            marker_size=10,
            text=texts,
            marker_color=vecs2color(X),
        ),
        go.Layout(
            width=500,
            xaxis=dict(title="dim 0"),
            yaxis=dict(title="dim 1"),
        ),
    )
    return fig


def date_ts_agg_events(df_agg, event_colors, show_types):
    """Show aggregated values per date."""
    assert "date" in df_agg

    fig = go.Figure(
        [
            go.Scatter(
                x=df_agg["date"],
                y=df_agg[c] + 100,
                name=c,
                mode="lines",
                line_color=event_colors[c],
            )
            for c in show_types
        ],
        # dict(yaxis=go.layout.YAxis(type="log")),
    )

    return fig
