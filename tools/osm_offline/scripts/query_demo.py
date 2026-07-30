#!/usr/bin/env python3
"""
Demo queries against an already-built survival SQLite DB.

Usage:
  python scripts/query_demo.py path/to/survival.sqlite --lat 28.61 --lon 77.20
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from osm_offline.query import find_nearby, reverse_geocode


def main() -> int:
    parser = argparse.ArgumentParser(description="Demo offline GIS queries")
    parser.add_argument("db", type=Path)
    parser.add_argument("--lat", type=float, required=True)
    parser.add_argument("--lon", type=float, required=True)
    parser.add_argument("--radius", type=float, default=3000.0)
    args = parser.parse_args()

    print("=== reverse_geocode ===")
    print(json.dumps(reverse_geocode(args.db, args.lat, args.lon), indent=2, ensure_ascii=False))

    for feature_type in ("hospital", "spring", "trail", "campsite", "lake"):
        print(f"\n=== find_nearby type={feature_type} ===")
        hits = find_nearby(
            args.db,
            args.lat,
            args.lon,
            args.radius,
            feature_type=feature_type,
            limit=5,
        )
        print(json.dumps(hits, indent=2, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
