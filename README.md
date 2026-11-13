<!-- TEMPLATE:START -->
> **This is a template repo.** Clone it, detach git, then run `make init`:
>
>     git clone --depth 1 <this-url> newproj
>     cd newproj && rm -rf .git && git init && git add -A && git commit -m init
>     make init && make setup
>
> Improve the template by editing it here and committing. Existing projects
> don't receive updates — each repo is a snapshot at creation time.
<!-- TEMPLATE:END -->

# PACKAGE

## Setup

Needs [uv](https://docs.astral.sh/uv/) only — no conda, no system Python:

    curl -LsSf https://astral.sh/uv/install.sh | sh

Then:

    make init      # rename PACKAGE, commit, offer to link storage (run once)
    make setup     # create .venv, install deps, register jupyter kernel
    make check     # show where DATA / OUT / REPORTS resolved

## Where data and output live

One variable, `$RESEARCH_STORAGE`, holds every project's storage:

    $RESEARCH_STORAGE/
    |-- PACKAGE/
    |   |-- data/        inputs
    |   |-- outputs/     disposable; regenerable from configs/ + a git SHA
    |   `-- reports/     curated figures worth sharing or keeping
    `-- other_project/
        `-- ...

One project's storage is one directory, so finishing a project means one
`tar`, and `du -sh $RESEARCH_STORAGE/*` tells you what is eating your quota.

Set it once per machine:

    export RESEARCH_STORAGE=$HOME/research        # laptop
    export RESEARCH_STORAGE=/scratch/you/research # cluster

`paths.py` exposes the three as `DATA`, `OUT`, `REPORTS`. Resolution order
for each, where NAME is `DATA` / `OUTPUT` / `REPORTS`:

1. `$PACKAGE_<NAME>` — one destination somewhere unusual
2. `$RESEARCH_STORAGE/PACKAGE/<dir>` — the normal case
3. `<repo>/<dir>` — fallback, or what a symlink points away from

Tier 1 is the escape hatch for a cluster where inputs sit on a read-only
shared mount while outputs go to scratch — the one case a single root can't
express. `make check` prints which tier won for each.

### Linking

`make link` symlinks `data/`, `outputs/` and `reports/` into
`$RESEARCH_STORAGE/PACKAGE/`, creating the directories if needed:

    make link        # offered by `make init`, or run any time

Safe to re-run: skips anything already linked, and refuses to touch a
directory that exists and has contents.

**One caveat on linking `reports/`.** It is tracked by default, so pointing
it outside the repo means its contents are no longer in git — only the
symlink gets committed, and an absolute path in git is wrong on the other
machine. If you link it, add `/reports/` to `.gitignore` and accept that
figures live outside version control. To keep them tracked, leave
`reports/` a real directory and link only `data/` and `outputs/`.

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

    make link      # symlink data/ outputs/ reports/ into $RESEARCH_STORAGE
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
- `reports/` — tracked by default. See the caveat above if you link it.

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
