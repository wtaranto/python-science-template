ENV := PACKAGE

.PHONY: detach init setup link check sync clean
.DEFAULT_GOAL := check

# Drop the template's git history and start this repo's own.
# Guarded by RUN_MAKE_INIT (absent in a real project) plus a confirmation,
# because this deletes .git irreversibly.
detach:
	@test -f RUN_MAKE_INIT || { echo "no RUN_MAKE_INIT here -- this is not an uninitialised template clone; refusing"; exit 1; }
	@git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository -- nothing to detach"; exit 1; }
	@o=$$(git remote get-url origin 2>/dev/null); \
	test -n "$$o" || { echo "no origin remote -- already detached, or never cloned; refusing"; exit 1; }; \
	echo "This will DELETE .git and start fresh history."; \
	echo "  current origin: $$o"; \
	echo "  commits to be discarded: $$(git rev-list --count HEAD 2>/dev/null)"; \
	printf "proceed? [y/N] "; \
	read a; \
	case "$$a" in [yY]*) ;; *) echo "aborted"; exit 1 ;; esac; \
	rm -rf .git; \
	git init -q; \
	git add -A; \
	git commit -qm "init from template"; \
	git branch -M main; \
	echo "detached -- now run: make init"

# Run once in a repo made from the template. Guarded by RUN_MAKE_INIT.
init:
	@test -f RUN_MAKE_INIT || { echo "already initialised (RUN_MAKE_INIT is gone)"; exit 1; }
	@git rev-parse HEAD >/dev/null 2>&1 || { echo "need a git repo with one commit -- run: git init && git add -A && git commit -m init"; exit 1; }
	@git remote get-url origin 2>/dev/null | grep -qi template && { echo "still linked to the template (origin: $$(git remote get-url origin))"; echo "detach first:  rm -rf .git && git init && git add -A && git commit -m init"; exit 1; } || true
	@printf "package name (lowercase, digits, underscores): "; \
	read n; \
	echo "$$n" | grep -qE "^[a-z][a-z0-9_]*$$" || { echo "bad name: lowercase letters, digits, underscores only"; exit 1; }; \
	git mv src/PACKAGE src/$$n; \
	perl -pi -e "s/PACKAGE/$$n/g" pyproject.toml Makefile README.md; \
	perl -0pi -e "s/<!-- TEMPLATE:START -->.*?<!-- TEMPLATE:END -->\n*//s" README.md; \
	git rm -q RUN_MAKE_INIT; \
	git add -A && git commit -qm "init $$n from template"; \
	echo "initialised as $$n"
	@if test -n "$$RESEARCH_STORAGE"; then \
	printf "link data/ outputs/ reports/ into \$$RESEARCH_STORAGE? [y/N] "; \
	read a; \
	case "$$a" in [yY]*) $(MAKE) --no-print-directory link ;; *) echo "  skipped -- run 'make link' any time" ;; esac; \
	else echo "  (\$$RESEARCH_STORAGE not set -- skipping link step)"; fi
	@echo "now run: make setup"

setup:
	uv sync
	uv run python -m ipykernel install --user --name $(ENV)

# Symlink data/ outputs/ reports/ into $RESEARCH_STORAGE/<pkg>/.
# Safe to re-run: skips anything already linked or non-empty.
link:
	@test -n "$$RESEARCH_STORAGE" || { echo "\$$RESEARCH_STORAGE is not set -- nothing to link"; exit 1; }
	@for d in data outputs reports; do \
	tgt="$$RESEARCH_STORAGE/$(ENV)/$$d"; \
	if test -L "$$d"; then echo "  ok    $$d/    -> $$(readlink $$d)"; continue; fi; \
	if test -d "$$d" && test -n "$$(ls -A $$d 2>/dev/null)"; then \
	echo "  SKIP  $$d/    exists and is not empty -- move its contents yourself"; continue; fi; \
	mkdir -p "$$tgt"; \
	if test -d "$$d"; then rmdir "$$d"; fi; \
	ln -s "$$tgt" "$$d"; \
	echo "  link  $$d/    -> $$tgt"; \
	if test "$$d" = reports; then \
	echo "        note: reports/ is tracked by default. Linked out of the"; \
	echo "        repo its contents are NOT in git -- add /reports/ to"; \
	echo "        .gitignore if that's what you want."; fi; \
	done

# Prints where DATA/OUT/REPORTS resolved -- run this first when a path is wrong.
check:
	@uv run python -c "import $(ENV).paths as p; \
	print(p.__file__); \
	print(); \
	print('DATA     ', p.DATA);    print('   via   ', p.DATA_VIA); \
	print('OUT      ', p.OUT);     print('   via   ', p.OUT_VIA); \
	print('REPORTS  ', p.REPORTS); print('   via   ', p.REPORTS_VIA)"

# Reconcile paired notebooks before committing.
sync:
	@find notebooks -maxdepth 1 \( -name '*.ipynb' -o -name '*.py' \) -print0 \
		| xargs -0 -r uv run jupytext --sync

# Wipes outputs/ only. reports/ is never touched here.
clean:
	find outputs/ -mindepth 1 -depth -delete 2>/dev/null || true
	rm -rf .pytest_cache
	find . -name __pycache__ -type d -exec rm -rf {} +
