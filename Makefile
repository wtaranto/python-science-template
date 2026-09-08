ENV := PACKAGE
SHELL := /bin/bash
SOLVER := $(shell command -v mamba >/dev/null 2>&1 && echo mamba || echo conda)

.PHONY: init setup update test lab check clean
.DEFAULT_GOAL: check

foo:
	@printf "$(SOLVER)"

init:
	@test -f .template || { echo "already initialised ('.template' is gone)"; exit 1; }
	@git rev-parse HEAD >/dev/null 2>&1 || { echo "need a git repo with one commit -- run: git init && git add -A && git commit -m init"; exit 1; }
	@test "$$(git remote get-url origin 2>/dev/null)" != "$$(cat .template)" || { \
		echo "still linked to the template -- detach first"; exit 1; }
	@printf "package name (lowercase, digits, underscores): "; \
	read n; \
	echo "$$n" | grep -qE "^[a-z][a-z0-9_]*$$" || { echo "bad name"; exit 1; }; \
	git mv src/PACKAGE src/$$n; \
	perl -pi -e "s/PACKAGE/$$n/g" pyproject.toml environment.yml Makefile README.md; \
	perl -0pi -e "s/<!-- TEMPLATE:START -->.*?<!-- TEMPLATE:END -->\n*//s" README.md; \
	git rm -q .template; \
	git add -A && git commit -qm "init $$n from template"; \
	echo "initialised as $$n -- now run: make setup"

setup:
	$(SOLVER) env create -f environment.yml
	$(SOLVER) run -n $(ENV) pip install -e .
	$(SOLVER) run -n $(ENV) python -m ipykernel install --user --name $(ENV)
	mkdir -p outputs

update:
	$(SOLVER) env update -f environment.yml --prune
	$(SOLVER) run -n $(ENV) pip install -e .

test:
	$(SOLVER) run -n $(ENV) pytest

lab:
	$(SOLVER) run -n $(ENV) jupyter lab

check:
	$(SOLVER) run -n $(ENV) python -c "import $(ENV); print($(ENV).__file__)"

clean:
	rm -rf outputs/* .pytest_cache
	find . -name __pycache__ -type d -exec rm -rf {} +
