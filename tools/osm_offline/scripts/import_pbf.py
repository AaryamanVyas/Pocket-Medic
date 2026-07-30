#!/usr/bin/env python3
"""Thin script wrapper: import a PBF into SQLite."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from osm_offline.cli import main

if __name__ == "__main__":
    # Default to the "import" subcommand if user passes raw args without it.
    argv = sys.argv[1:]
    if argv and argv[0] not in {"import", "nearby", "reverse", "types", "-h", "--help"}:
        argv = ["import", *argv]
    raise SystemExit(main(argv))
