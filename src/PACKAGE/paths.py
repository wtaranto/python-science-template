"""Machine-independent paths.

Data root resolution, in order:
  1. $<PKG>_DATA  (e.g. MMS_VDF_FIT_DATA) -- this project, this machine
  2. $RESEARCH_DATA/<pkg>                 -- shared root, per-project subdir
  3. <repo>/data                          -- default, often a symlink

No literal data paths belong anywhere else in the codebase.
"""

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_PKG = Path(__file__).resolve().parent.name
DATA_ENV = f"{_PKG.upper()}_DATA"

if os.environ.get(DATA_ENV):
    DATA = Path(os.environ[DATA_ENV])
elif os.environ.get("RESEARCH_DATA"):
    DATA = Path(os.environ["RESEARCH_DATA"]) / _PKG
else:
    DATA = ROOT / "data"

OUT = ROOT / "outputs"
