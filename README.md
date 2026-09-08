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

    make init      # rename PACKAGE, strip this notice, commit (run once per project)
    make setup     # create env, editable install, register kernel
    make check     # confirm imports resolve

## On the cluster

    <module load line goes here>
    export PROJECT_DATA=/path/to/data
    make setup

Set `PROJECT_DATA` per machine. No literal data paths anywhere else.

## Commands

    make lab       # jupyter lab in this env
    make test      # pytest
    make update    # after editing environment.yml
    make clean     # wipe outputs/ and caches

## Layout

- `notebooks/` — exploration. `.py` pairs committed, `.ipynb` ignored.
- `scripts/` — entry points. Never promoted; hollow them out instead.
- `configs/` — run configs.
- `src/PACKAGE/scratch.py` — reused, contract still moving, untested.
- `src/PACKAGE/sturdy.py` — stable contract, tested.
- `src/PACKAGE/paths.py` — the only place literal paths live.
- `tests/` — mirrors sturdy only. Scratch has no tests by definition.
- `outputs/` — disposable. Regenerable from `configs/` + a git SHA.

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
