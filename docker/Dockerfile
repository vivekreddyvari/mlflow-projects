FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY pyproject.toml README.md ./
COPY src ./src

RUN pip install --no-cache-dir -e .

CMD ["python", "-c", "import mlflow_projects; print(mlflow_projects.__doc__ or 'mlflow-projects')"]
