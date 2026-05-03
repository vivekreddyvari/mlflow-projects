#!/usr/bin/env bash
# CI steps invoked by GitHub Actions (.pipelines/github/ci.yml).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python -m ruff check src tests
python -m pytest
