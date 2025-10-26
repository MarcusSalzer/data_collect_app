"""Utilities for Embeddings (mostly sklearn)."""

from typing import Any, Literal

import numpy as np
import polars as pl
import umap
from numpy.typing import NDArray
from sklearn.decomposition import PCA
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.pipeline import FunctionTransformer, Pipeline
from sklearn.preprocessing import StandardScaler


def make_embedding_pipe(
    input_transfrom: Literal["std", "tfidf", "tfidf+std"],
    reduction: Literal["pca", "umap"],
    transp_between: bool = False,
    norm_out: Literal["std"] | None = None,
    ncomp: int = 3,
):
    """Build a pipeline for dimensionality reduction."""

    steps: list[tuple[str, Any]] = []

    if input_transfrom == "std":
        steps.append(("normalize", StandardScaler()))
    elif input_transfrom.startswith("tfidf"):
        steps.append(("tfidf", TfidfTransformer()))
        steps.append(
            (
                "todense",
                FunctionTransformer(lambda x: np.array(x.todense())),
            )
        )
        if input_transfrom == "tfidf+std":
            steps.append(("normalize", StandardScaler()))
    else:
        raise ValueError("unknown input transform")

    # --- optionally transpose ---
    if transp_between:
        steps.append(("transpose", FunctionTransformer(lambda x: x.T)))

    # --- dimensionality reduction ---
    if reduction == "pca":
        steps.append(("pca", PCA(ncomp)))
    elif reduction == "umap":
        steps.append(("umap", umap.UMAP(n_neighbors=4, n_components=ncomp)))
    else:
        raise ValueError("unknown reduction")

    # --- optionally normalize output ---
    if norm_out == "std":
        steps.append(("norm_out", StandardScaler()))

    return Pipeline(steps)


def compare_embs(a: NDArray, b: NDArray, metric: Literal["L2", "L1", "cosine"]):
    """Compare embeddings with some metric"""
    if a.ndim == 1:
        a = a.reshape(1, -1)

    if metric in ("L1", "L2"):
        dist = np.linalg.norm(
            a - b,
            axis=-1,
            ord=1 if metric == "L1" else 2,
        )
    elif metric == "cosine":
        dist = a.dot(b) / (np.linalg.norm(a, axis=-1) * np.linalg.norm(b))
    else:
        raise ValueError(f"Unknown metric: {metric}")
    assert isinstance(dist, np.ndarray), f"{type(dist)=}"
    return dist


def find_all_closest(
    all_embs: NDArray,
    labels: list[str],
    queries: list[str],
    metric: Literal["L2", "L1", "cosine"] = "L2",
    top_count: int = 3,
    verbose: bool = False,
):
    """Find closest embeddings for all queries"""
    assert set(queries).issubset(labels), "all queries must be in the labels"
    assert len(all_embs) == len(labels), (
        f"got {len(labels)} labels and {len(all_embs)} embeddings"
    )

    assert all_embs.ndim == 2, f"got {all_embs.ndim}, expected 2-dim array"

    label2idx = {lab: idx for idx, lab in enumerate(labels)}

    results: dict[str, list[tuple[str, float]]] = {}
    for q in queries:
        emb_q = all_embs[label2idx[q]]

        dist = compare_embs(all_embs, emb_q, metric)
        sort_order = -1 if metric == "cosine" else 1  # maximize or minimize
        idxs = (sort_order * dist).argsort()[:top_count]

        results[q] = [(labels[i], dist[i].item()) for i in idxs]

    for k, res in results.items():
        assert k == res[0][0], "any query should rank itself first"

    if verbose:
        max_res_len = max(len(lab) for r in results.values() for lab, d in r)
        for k, res in results.items():
            print(" ".join(f"{lab}: {d:.2f}".ljust(max_res_len + 5) for lab, d in res))

    return results


def eval_triples(
    all_embs: NDArray,
    labels: list[str],
    triples: pl.DataFrame,
    metric: Literal["L2", "L1", "cosine"] = "L2",
):
    """Evaluate triples."""
    label2idx = {lab: idx for idx, lab in enumerate(labels)}

    sort_order = -1 if metric == "cosine" else 1  # maximize or minimize
    res_p, res_n = [], []  # positive and negative
    for t in triples.iter_rows():
        idxs = [label2idx[e] for e in t]
        r_p = compare_embs(all_embs[idxs[0]], all_embs[idxs[1]], metric).item()
        r_n = compare_embs(all_embs[idxs[0]], all_embs[idxs[2]], metric).item()
        res_p.append(sort_order * r_p)
        res_n.append(sort_order * r_n)

    triples = triples.with_columns(
        pl.Series("dist_p", res_p),
        pl.Series("dist_n", res_n),
    ).with_columns(correct=pl.col("dist_p") < pl.col("dist_n"))

    accuracy = triples["correct"].mean()

    return triples, accuracy


def eval_subj(
    embs: NDArray,
    labels: list[str],
    triples: pl.DataFrame,
    metrics=("L1", "L2", "cosine"),
):
    """Evaluate embeddings on triples and format a string with accuracies."""
    accs = {}
    for metric in metrics:
        _, a = eval_triples(embs, labels, triples, metric=metric)
        accs[metric] = a

    # avg_acc = sum(accs.values()) / len(accs)
    return ",\t".join(f"{m}: {a:.0%}" for m, a in accs.items())
