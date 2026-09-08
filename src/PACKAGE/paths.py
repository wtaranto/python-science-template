"""Machine-independent paths.

Set PROJECT_DATA to override the default of <repo>/data.
No literal data paths belong anywhere else in the codebase.
"""

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = Path(os.environ.get("PROJECT_DATA") or ROOT / "data")
OUT = ROOT / "outputs"
