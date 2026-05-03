# mlflow-projects

Python package and automation layout for **MLflow** experiments: tracking, scripts, notebooks, and CI across common Git hosts.

## Layout

| Path | Purpose |
|------|---------|
| `src/mlflow_projects/` | Installable package code |
| `scripts/` | Runnable pipelines (e.g. training) |
| `notebooks/` | Exploratory work |
| `config/` | YAML/JSON configs for runs |
| `experiment_tracking/` | Default local file store (ignored except `.gitkeep`) |
| `docker/` | Container image for repeatable runs |
| `docs/` | Long-form documentation |
| `examples/` | Small runnable samples |
| `.agents/skills/` | Agent-oriented skill buckets (`readme`, `docs`, `presentation`, …) |
| `.pipelines/` | CI shell (`ci.sh`) and canonical workflow YAML (`github/ci.yml`; mirrored under `.github/workflows/`) |
| `.github/` | GitHub Actions entrypoint, Dependabot, issue/PR templates |
| `.gitlab/` | GitLab issue & merge request templates |
| `.forgejo/` | Forgejo/Codeberg-compatible workflows |
| `.gitlab-ci.yml` | GitLab CI pipeline |

## Quick start

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
cp .env.example .env
pytest
python scripts/train_example.py
```

## Conventions

- Prefer `pyproject.toml` for dependencies; `requirements.txt` is for pinned/deploy installs.
- Point `MLFLOW_TRACKING_URI` at a shared server for team workflows; the repo defaults to a **local file** store under `experiment_tracking/`.

## License

MIT — see `LICENSE`.
