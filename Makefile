ENV := PACKAGE

.PHONY: init setup update test lab check clean ipynb-sync
.DEFAULT_GOAL := check

setup:
	uv sync
	uv run python -m ipykernel install --user --name $(ENV)
	mkdir -p outputs data

update:
	uv sync

test:
	uv run pytest

lab:
	uv run jupyter lab

check:
	uv run python -c "import $(ENV); print($(ENV).__file__)"

ipynb-sync:
	uv run jupytext --sync notebooks/*.ipynb notebooks/*.py

clean:
	rm -rf outputs/* .pytest_cache
	find . -name __pycache__ -type d -exec rm -rf {} +
