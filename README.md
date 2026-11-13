<!-- TEMPLATE:START -->
> **This is a template repo.** Clone it, then run the three commands below.
> `RUN_MAKE_INIT` in the repo root is the reminder that none of them have
> run yet; `make init` deletes it.
>
>     git clone --depth 1 <this-url> newproj
>     cd newproj
>     make detach    # drop template history, start this repo's own
>     make init      # rename PACKAGE, offer to link storage
>     make setup
>
> Improve the template by editing it here and committing. Existing projects
> don't receive updates — each repo is a snapshot at creation time.
<!-- TEMPLATE:END -->

# PACKAGE

## Setup

Needs [uv](https://docs.astral.sh/uv/) only — no conda, no system Python:

    curl -LsSf https://astral.sh/uv/install.sh | sh

Then:

    make detach    # drop the template's git history (run once, first)
    make init      # rename PACKAGE, commit, offer to link storage (run once)
    make setup     # create .venv, install deps, register jupyter kernel
    make check     # show where DATA / OUT / REPORTS resolved

## Where data and output live

**Bulk lives outside the repo; keepers live inside it.**

`$RESEARCH_STORAGE` holds the bulk for every project:

    $RESEARCH_STORAGE/
    |-- PACKAGE/
    |   |-- data/        inputs
    |   `-- outputs/     disposable; regenerable from configs/ + a git SHA
    `-- other_project/
        `-- ...

One project's bulk is one directory, so finishing a project means one
`tar`, and `du -sh $RESEARCH_STORAGE/*` tells you what is eating quota.

Set it once per machine:

    export RESEARCH_STORAGE=$HOME/research        # laptop
    export RESEARCH_STORAGE=/scratch/you/research # cluster

`paths.py` exposes three names:

- `DATA` → inputs. Gitignored.
- `OUT` → `outputs/`. Disposable, regenerable, gitignored, wiped by
  `make clean`.
- `REPORTS` → `reports/`. Curated figures, **tracked by git**.

`DATA` and `OUT` resolve in order: `$PACKAGE_DATA` / `$PACKAGE_OUTPUT`, then
`$RESEARCH_STORAGE/PACKAGE/<dir>`, then `<repo>/<dir>`. The first is the
escape hatch for a cluster where inputs sit on a read-only shared mount
while outputs go to scratch.

**`REPORTS` is deliberately not routed through `$RESEARCH_STORAGE`.** It is
always `<repo>/reports`, because git cannot follow a symlink or track
anything outside the repo — put figures in storage and they are no longer
versioned. `$PACKAGE_REPORTS` overrides it if you really want that, and
`make check` says so explicitly when it is in effect.

### Linking

`make link` symlinks `data/` and `outputs/` into
`$RESEARCH_STORAGE/PACKAGE/`, creating the directories as needed:

    make link        # offered by `make init`, or run any time

`reports/` is never linked, for the reason above. Linking is safe to re-run:
it skips anything already linked and refuses to touch a directory that
exists and has contents.

### Writing

Nothing in `paths.py` creates directories — importing a module shouldn't
touch the filesystem. Call `mkdir` where you write:

    for d in (OUT, REPORTS):
        d.mkdir(parents=True, exist_ok=True)
        fig.savefig(d / "psd_overview.png", dpi=150)

If that pattern shows up in a third place it has earned promotion to
`sturdy` under the rules below — same gate as any other function.

## Cluster

    <module load line goes here, if any>
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export RESEARCH_STORAGE=/scratch/you/research
    make link
    make setup

`uv.lock` is committed, so the cluster resolves to exactly the laptop's
versions. For a batch job that doesn't need Jupyter: `uv sync --no-dev`.

## Commands

    make link      # symlink data/ and outputs/ into $RESEARCH_STORAGE
    make sync      # reconcile jupytext notebook pairs before committing
    make clean     # wipe outputs/ (leaves reports/ alone) and caches

Everything else runs through `uv` directly, no wrapper needed:

    uv run jupyter lab
    uv run pytest
    uv add <pkg>          # also updates uv.lock and .venv
    uv add --dev <pkg>
    uv sync               # after hand-editing pyproject.toml deps

## Layout

- `notebooks/` — exploration. `.py` pairs committed, `.ipynb` ignored.
- `scripts/` — entry points. Never promoted; hollow them out instead.
- `configs/` — run configs. Run configuration, not machine configuration.
- `src/PACKAGE/scratch.py` — reused, contract still moving, untested.
- `src/PACKAGE/sturdy.py` — stable contract, tested.
- `src/PACKAGE/paths.py` — the only place literal paths live.
- `tests/` — mirrors sturdy only. Scratch has no tests by definition.
- `data/`, `outputs/` — gitignored; usually symlinks (`make link`).
- `reports/` — tracked, always inside the repo, never linked.

## Promotion: scratch -> sturdy

All three required:

1. **Third actual call site.** Not the third time you thought about reusing
   it. A signature change to fit a new caller resets the count.
2. **A test you can write in ten minutes.** If you can't, the function does
   several things — split it first.
3. **Deleted from scratch in the same commit**, imports fixed.

Exception: contracts fixed externally (coordinate transforms, unit
conversions, file format specs) promote on first sight — there's no
signature left to discover.

Demotion is allowed. Three behaviour-changing commits in a month means it
wasn't stable.

## Habits

- Compute functions are pure: params in, array out. No globals, no file
  writes, no plotting inside.
- Split stable cores from volatile policy. A loader that "keeps needing new
  arguments" is usually a stable reader fused to study-specific defaults.
- Code moves between machines by git only. Data never through git.
- Never edit on laptop and cluster in the same session. Commit before switching.
- Print the git SHA at the top of every cluster run.

## Reusing code from a finished project

Copy the functions plus their tests; note origin in a header comment
(`# from proj-a @ <sha>`). Build a shared library on the third copy, or when
a copy needed no modification. Finished projects keep their copies.
