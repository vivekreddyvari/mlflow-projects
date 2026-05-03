# CI/CD on GitHub Actions

This document describes how continuous integration is wired for **mlflow-projects**: which files matter, when jobs run, and what each step does. The design uses a **thin GitHub Actions workflow** plus a **shared shell script** so the same commands are easy to run locally and to keep in sync.

## Architecture

| Layer | Path | Role |
|--------|------|------|
| **Workflow entrypoint (required by GitHub)** | `.github/workflows/ci.yml` | Defines *when* CI runs and *how* the runner is prepared. GitHub only loads workflows from `.github/workflows/`. |
| **Canonical workflow copy** | `.pipelines/github/ci.yml` | Same YAML as above, kept as the “source of truth” under `.pipelines/`. Update **both** files together when you change triggers or job structure. |
| **Shared pipeline logic** | `.pipelines/ci.sh` | Install, lint, and test commands. Invoked by the workflow’s last step. |
| **Dependency / action updates** | `.github/dependabot.yml` | Opens PRs to bump **pip** and **GitHub Actions** dependencies on a schedule (separate from the `CI` workflow, but part of overall automation). |

Flow:

```text
git push / pull_request (eligible branches)
        │
        ▼
.github/workflows/ci.yml  ──►  ubuntu-latest runner
        │                      ├── checkout
        │                      ├── setup-python (matrix: 3.10, 3.11, 3.12)
        │                      └── bash .pipelines/ci.sh
        ▼
   success / failure  →  GitHub Checks UI
```

## When the `CI` workflow runs

Triggers are defined under `on:` in the workflow file.

### `push`

A push of new commits to **either** branch runs the workflow:

- `main`
- `feature/prod/project-learning`

### `pull_request`

The workflow runs for pull requests whose **base** (target) branch is:

- `main`, or
- `feature/prod/project-learning`

So a PR from `feature/dev/project-learning` **into** `main` runs CI. Pushes to `feature/dev/project-learning` **without** a PR targeting those base branches do **not** trigger this workflow via `push` (only `main` and `feature/prod/project-learning` are listed under `push`).

### Concurrency

```yaml
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

- **`group`**: One in-flight run per workflow name + ref (branch or PR merge ref). New pushes supersede older runs on the same ref.
- **`cancel-in-progress: true`**: When a new run starts for the same group, GitHub **cancels** the older run to save minutes and avoid stale results.

## Workflow file (GitHub entrypoint)

Below is the workflow as committed under `.github/workflows/ci.yml`. It is mirrored in `.pipelines/github/ci.yml`.

```yaml
# Mirrors .pipelines/github/ci.yml — GitHub executes workflows only from this directory.
name: CI

on:
  push:
    branches:
      - main
      - feature/prod/project-learning
  pull_request:
    branches:
      - main
      - feature/prod/project-learning

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.10", "3.11", "3.12"]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: pip

      - name: Run pipeline
        run: bash .pipelines/ci.sh
```

### Job: `test`

- **`runs-on: ubuntu-latest`**: Hosted Linux runner maintained by GitHub.
- **`strategy.fail-fast: false`**: If one matrix cell (e.g. Python 3.11) fails, the others **still run** so you see all version failures in one run.
- **`matrix.python-version`**: Runs the same pipeline **three times**, once per listed Python version. This matches `requires-python = ">=3.10"` in `pyproject.toml`.

### Steps (in order)

1. **`actions/checkout@v4`**  
   Clones the repository at the commit that triggered the workflow (shallow clone by default).

2. **`actions/setup-python@v5`**  
   Installs the matrix Python version and enables **`cache: pip`** so repeated runs reuse pip’s cache when dependencies are unchanged.

3. **`bash .pipelines/ci.sh`**  
   Runs the shared script at the repo root (path is relative to the checked-out tree). All linting and testing happens here.

## Shared script: `.pipelines/ci.sh`

```bash
#!/usr/bin/env bash
# CI steps invoked by GitHub Actions (.pipelines/github/ci.yml).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python -m ruff check src tests
python -m pytest
```

### Line-by-line behavior

| Lines | Purpose |
|--------|---------|
| `set -euo pipefail` | Exit on error, treat unset variables as errors, fail pipelines on first failing command in a pipe. |
| `ROOT=...` / `cd "$ROOT"` | Resolve the **repository root** regardless of current working directory, so the script behaves the same when called from GitHub Actions or manually. |
| `pip install --upgrade pip` | Ensures a recent pip before installing the project. |
| `pip install -e ".[dev]"` | Editable install of **mlflow-projects** with **dev** extras from `pyproject.toml` (`pytest`, `ruff`, etc.). |
| `ruff check src tests` | Static analysis / lint for everything under `src/` and `tests/`. |
| `pytest` | Runs the test suite; paths and `pythonpath` come from `[tool.pytest.ini_options]` in `pyproject.toml`. |

### Run the same checks locally

From the repository root (with a virtualenv activated if you use one):

```bash
bash .pipelines/ci.sh
```

This is the closest equivalent to what GitHub runs for each matrix job (your laptop Python version may differ from 3.10–3.12 unless you use those interpreters).

## Dependabot (related automation)

`.github/dependabot.yml` configures **scheduled** update PRs:

- **pip** (`directory: "/"`): suggests bumps for Python dependencies declared for Dependabot’s scan (e.g. `requirements.txt` / manifest it detects).
- **github-actions**: suggests new major/minor versions of Actions used in workflows (e.g. `actions/checkout`).

Merging those PRs triggers **`CI`** when the target branch is `main` or `feature/prod/project-learning`, same as any other push.

## Other CI files in this repo (not GitHub Actions)

These are useful if you mirror the project on GitLab or Codeberg; they duplicate the **intent** of lint + test but do **not** call `.pipelines/ci.sh` today:

| File | Platform |
|------|----------|
| `.gitlab-ci.yml` | GitLab CI: `ruff` job + `pytest` matrix on `python:*-slim` images. |
| `.forgejo/workflows/ci.yml` | Forgejo / Codeberg-style workflow (syntax similar to GitHub Actions). |

If you want a **single** command source everywhere, you could change those pipelines to invoke `bash .pipelines/ci.sh` after checkout (where the runner supports bash).

## Changing or extending this setup

| Goal | What to change |
|------|----------------|
| Run CI on more branches | Add branch names under `on.push.branches` and/or `on.pull_request.branches` in **both** `.github/workflows/ci.yml` and `.pipelines/github/ci.yml`. |
| Add another Python version | Extend `matrix.python-version` in both YAML files; ensure `pyproject.toml` still supports that version. |
| Add type checking or coverage | Extend `.pipelines/ci.sh` (e.g. `mypy`, `pytest --cov`) and fix any new failures locally first. |
| Skip slow tests in CI | Use pytest markers and run `pytest -m "not slow"` in `ci.sh`, or split into multiple jobs in the workflow. |
| Deploy after success | Add a new **job** that `needs: test` and runs only on `main` (or tags), with secrets for your target (e.g. Databricks, container registry). |

## See also

- Root `README.md` — project layout including `.pipelines/` and `.github/`.
- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
