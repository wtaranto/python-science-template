"""Stable contract, tested.

Promotion gate:
  1. Third actual call site (a signature change resets the count).
  2. Invariant test writable in <10 min (if not, split the function first).
  3. Delete from scratch and fix imports in the SAME commit.

Exception: contracts fixed externally (coordinate transforms, unit
conversions, file format specs) promote on first sight.

Demotion is allowed and normal.
"""
