"""Machine-independent paths.

Bulk lives outside the repo; keepers live inside it.

$RESEARCH_STORAGE holds the bulk for every project:

    $RESEARCH_STORAGE/
    |-- <pkg>/           this project, named after the package
    |   |-- data/        inputs
    |   `-- outputs/     disposable; regenerable from configs/ + a git SHA
    `-- other_project/
        `-- ...

One project's bulk is one directory: easy to archive, delete or measure
(`du -sh $RESEARCH_STORAGE/*`) when the project is finished.

DATA and OUT resolve, for NAME in DATA / OUTPUT:

  1. $<PKG>_<NAME>                 one destination somewhere unusual
  2. $RESEARCH_STORAGE/<pkg>/<dir>  the normal case
  3. <repo>/<dir>                   fallback, or what a symlink points from

Tier 1 is the escape hatch for a cluster where inputs live on a read-only
shared mount while outputs go to scratch.

REPORTS is different and deliberately NOT routed through
$RESEARCH_STORAGE: it is always <repo>/reports, because it is tracked by
git, and git cannot follow a symlink or track anything outside the repo.
$<PKG>_REPORTS still overrides it, but doing so gives up version control
over the figures.

  DATA     inputs; read-only as far as this code is concerned
  OUT      disposable, outside the repo
  REPORTS  keepers, inside the repo and committed

No literal paths belong anywhere else in the codebase.

Nothing here creates directories -- importing a module should not touch the
filesystem. Call `d.mkdir(parents=True, exist_ok=True)` where you write.

Debugging a wrong path:  make check
"""

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PKG = Path(__file__).resolve().parent.name

STORAGE_ENV = "RESEARCH_STORAGE"


def _resolve(name: str, dirname: str) -> tuple[Path, str]:
    """Resolve one destination, returning (path, how-it-resolved)."""
    own = f"{PKG.upper()}_{name}"

    if os.environ.get(own):
        return Path(os.environ[own]), f"${own}"

    store = os.environ.get(STORAGE_ENV)
    if store:
        return Path(store) / PKG / dirname, f"${STORAGE_ENV}/{PKG}/{dirname}"

    path = ROOT / dirname
    if path.is_symlink():
        return path, f"<repo>/{dirname} -> {os.readlink(path)}"
    return path, f"<repo>/{dirname} (set ${STORAGE_ENV} or ${own} to override)"


DATA, DATA_VIA = _resolve("DATA", "data")
OUT, OUT_VIA = _resolve("OUTPUT", "outputs")

# Tracked, so it must stay inside the repo. $RESEARCH_STORAGE is not
# consulted -- see the note above.
if os.environ.get(f"{PKG.upper()}_REPORTS"):
    REPORTS = Path(os.environ[f"{PKG.upper()}_REPORTS"])
    REPORTS_VIA = f"${PKG.upper()}_REPORTS (NOT tracked by git)"
else:
    REPORTS = ROOT / "reports"
    REPORTS_VIA = "<repo>/reports (tracked)"

# Env var names, for error messages and `make check`.
DATA_ENV = f"{PKG.upper()}_DATA"
OUT_ENV = f"{PKG.upper()}_OUTPUT"
REPORTS_ENV = f"{PKG.upper()}_REPORTS"
