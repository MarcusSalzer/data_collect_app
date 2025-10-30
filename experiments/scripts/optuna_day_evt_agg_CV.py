"""Train and evaluate the daily data classifier.

- tune hyperparameters using Cross Validation (inside optuna)
- Final "unseen" performance estimated from "val"-split

"""

import sys
import warnings

import lightgbm as lgb
import optuna
import polars as pl
from sklearn.model_selection import cross_val_score

sys.path.append("src")

# LGBM is loud...
warnings.filterwarnings("ignore", category=UserWarning)

import evt_embeddings as ee
import util_agg

MULTI_TARGETS = ["weekday", "location", "cld_sym", "headache", "c"]

AVG_ALL_TARGETS = False

CV_FOLDS = 5

## load day-vectors
df_evt = pl.read_parquet("tmp_data/agg_day.parquet")
evt_types = df_evt.columns[1:]

print(f"loaded evts: {df_evt.shape}")

# load extra data
df_health = pl.read_csv(
    "aux_data/health_daily.csv",
    infer_schema_length=None,
    try_parse_dates=True,
)
print(f"loaded extra data: {df_health.shape}")


df = df_evt.join(df_health, on="date", how="left", suffix="_HD")


data = util_agg.DailyEvtAggDataset(df, features=evt_types, seed=1337)

print(data)


def _get_params(trial: optuna.Trial):
    prep = ee.make_embedding_pipe(
        trial.suggest_categorical("prep", ["std", "tfidf", "tfidf+std"]),
        reduction=None,
    )

    lgb_params = {
        "num_leaves": trial.suggest_int("lgb_num_leaves", 2, 16),
        "max_depth": trial.suggest_int("lgb_max_depth", 2, 8),
        "reg_alpha": trial.suggest_float("lgb_reg_alpha", 0.01, 0.9),
        "reg_lambda": trial.suggest_float("lgb_reg_lambda", 0.01, 0.9),
        "n_estimators": 100,
    }
    return prep, lgb_params


def objective(trial: optuna.Trial, target: str):
    prep, lgb_params = _get_params(trial)

    clf = lgb.LGBMClassifier(
        force_row_wise=True,
        verbose=-1,
        verbosity=-1,
        **lgb_params,
    )  # pyright: ignore[reportGeneralTypeIssues]

    splits, null_acc, mode_acc = data.preprocessed_splits(prep, target)

    trial.study.set_user_attr(f"null_acc_{target}", null_acc)
    trial.study.set_user_attr(f"mode_acc_{target}", mode_acc)

    X_train, y_train = splits["train"]

    clf.fit(X_train, y_train)

    val_acc = clf.score(*splits["val"])  # pyright: ignore[reportAttributeAccessIssue]
    trial.set_user_attr("val_acc", val_acc)
    scores = cross_val_score(clf, X_train, y_train, cv=CV_FOLDS, scoring="accuracy")  # type: ignore

    return scores.mean()


def objective_multi(trial: optuna.Trial):
    scores = {k: objective(trial, k) for k in MULTI_TARGETS}
    trial.set_user_attr("scores", scores)
    return sum(scores.values()) / len(scores)


if __name__ == "__main__":
    if AVG_ALL_TARGETS:
        print(f"[NOTE] Averaging over {len(MULTI_TARGETS)} targets!")
        study = optuna.create_study(
            storage="sqlite:///tmp_data/optuna.db",
            study_name="lgbm_cv_multi",
            load_if_exists=True,
            direction="maximize",
        )
        study.set_user_attr("multi_targets", MULTI_TARGETS)
        study.optimize(objective_multi, n_trials=30)

    else:
        for target in MULTI_TARGETS:
            study = optuna.create_study(
                storage="sqlite:///tmp_data/optuna.db",
                study_name=f"lgbm_cv_{target}",
                load_if_exists=True,
                direction="maximize",
            )
            study.optimize(lambda tr: objective(tr, target), n_trials=30)
