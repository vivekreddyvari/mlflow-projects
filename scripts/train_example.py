#!/usr/bin/env python3
"""Minimal MLflow logging example; extend for real training pipelines."""

from __future__ import annotations

import os

import mlflow


def main() -> None:
    uri = os.environ.get("MLFLOW_TRACKING_URI", "file:./experiment_tracking")
    mlflow.set_tracking_uri(uri)
    mlflow.set_experiment(os.environ.get("MLFLOW_EXPERIMENT_NAME", "sandbox"))

    with mlflow.start_run():
        mlflow.log_param("demo", True)
        mlflow.log_metric("example_metric", 1.0)
        print(f"Run ID: {mlflow.active_run().info.run_id}")


if __name__ == "__main__":
    main()
