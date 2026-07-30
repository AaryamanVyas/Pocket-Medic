"""
Command-line interface for offline OSM → SQLite tooling.

Examples
--------
  python -m osm_offline import path/to/region.osm.pbf -o data/survival.sqlite
  python -m osm_offline nearby data/survival.sqlite --lat 28.61 --lon 77.20 -r 5000 -t hospital
  python -m osm_offline reverse data/survival.sqlite --lat 28.61 --lon 77.20
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .feature_types import FEATURE_TYPES
from .importer import import_pbf_to_sqlite
from .query import find_nearby, reverse_geocode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="osm_offline",
        description="Offline OSM PBF → SQLite survival database toolkit",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    imp = sub.add_parser("import", help="Convert .osm.pbf into SQLite")
    imp.add_argument("pbf", type=Path, help="Path to regional .osm.pbf")
    imp.add_argument(
        "-o",
        "--output",
        type=Path,
        required=True,
        help="Output SQLite path (e.g. data/survival.sqlite)",
    )
    imp.add_argument(
        "--append",
        action="store_true",
        help="Do not wipe existing tables (default is replace)",
    )
    imp.add_argument(
        "--flush-every",
        type=int,
        default=5000,
        help="Buffered feature count before each SQLite write",
    )

    near = sub.add_parser("nearby", help="Find features near a coordinate")
    near.add_argument("db", type=Path, help="SQLite database path")
    near.add_argument("--lat", type=float, required=True)
    near.add_argument("--lon", type=float, required=True)
    near.add_argument("-r", "--radius", type=float, default=2000.0, help="Radius meters")
    near.add_argument(
        "-t",
        "--type",
        choices=FEATURE_TYPES,
        default=None,
        help="Optional feature type filter",
    )
    near.add_argument("--limit", type=int, default=20)

    rev = sub.add_parser("reverse", help="Nearest city/town/village")
    rev.add_argument("db", type=Path, help="SQLite database path")
    rev.add_argument("--lat", type=float, required=True)
    rev.add_argument("--lon", type=float, required=True)
    rev.add_argument(
        "--max-radius",
        type=float,
        default=50000.0,
        help="Max search radius in meters",
    )

    types = sub.add_parser("types", help="List supported feature types")
    types.add_argument("--json", action="store_true")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.command == "types":
        if args.json:
            print(json.dumps(list(FEATURE_TYPES), indent=2))
        else:
            for t in FEATURE_TYPES:
                print(t)
        return 0

    if args.command == "import":
        stats = import_pbf_to_sqlite(
            args.pbf,
            args.output,
            replace=not args.append,
            flush_every=args.flush_every,
        )
        print(json.dumps(stats, indent=2))
        return 0

    if args.command == "nearby":
        results = find_nearby(
            args.db,
            args.lat,
            args.lon,
            args.radius,
            feature_type=args.type,
            limit=args.limit,
        )
        print(json.dumps(results, indent=2, ensure_ascii=False))
        return 0

    if args.command == "reverse":
        hit = reverse_geocode(
            args.db,
            args.lat,
            args.lon,
            max_radius_meters=args.max_radius,
        )
        print(json.dumps(hit, indent=2, ensure_ascii=False))
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
