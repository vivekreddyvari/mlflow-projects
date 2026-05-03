.PHONY: install dev test lint fmt clean

install:
	python -m pip install -e .

dev:
	python -m pip install -e ".[dev]"

test:
	python -m pytest

lint:
	python -m ruff check src tests

fmt:
	python -m ruff format src tests

clean:
	rm -rf build dist .pytest_cache .ruff_cache *.egg-info
