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
import traceback
from pathlib import Path
from typing import Optional

from .feature_types import FEATURE_TYPES
from .importer import import_pbf_to_sqlite
from .paths import expand_user_path, resolve_pbf_path, search_osm_pbf
from .query import find_nearby, reverse_geocode

# Demo coordinates used for post-import verification (Bengaluru).
VERIFY_LAT = 12.9716
VERIFY_LON = 77.5946


def _print_json(payload: object) -> None:
    """Print JSON safely on Windows cp1252 consoles (OSM names may be Unicode)."""
    text = json.dumps(payload, indent=2, ensure_ascii=False)
    try:
        print(text)
    except UnicodeEncodeError:
        # Fallback: escape non-ASCII so PowerShell/cp1252 never crashes.
        print(json.dumps(payload, indent=2, ensure_ascii=True))


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
        "--yes",
        "-y",
        action="store_true",
        help="Overwrite existing SQLite without prompting",
    )
    imp.add_argument(
        "--no-discover",
        action="store_true",
        help="Disable auto-search for missing PBF paths",
    )
    imp.add_argument(
        "--no-verify",
        action="store_true",
        help="Skip automatic reverse/nearby checks after import",
    )
    imp.add_argument(
        "--flush-every",
        type=int,
        default=5000,
        help="Buffered feature count before each SQLite write",
    )
    imp.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        default=True,
        help="Verbose path/logging output (default: on)",
    )
    imp.add_argument(
        "--quiet",
        "-q",
        action="store_true",
        help="Reduce logging",
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

    find = sub.add_parser("find-pbf", help="Search common folders for *.osm.pbf")
    find.add_argument(
        "--name",
        default=None,
        help="Optional filename hint (e.g. southern-zone-260729.osm.pbf)",
    )

    return parser


def _log(verbose: bool, message: str) -> None:
    if verbose:
        print(message, flush=True)


def _confirm_overwrite(path: Path, *, assume_yes: bool) -> bool:
    if assume_yes:
        return True
    if not sys.stdin.isatty():
        print(
            f"ERROR: Output already exists: {path}\n"
            "Re-run with --yes to overwrite in non-interactive mode.",
            file=sys.stderr,
        )
        return False
    answer = input(f"Output already exists: {path}\nOverwrite? [y/N]: ").strip().lower()
    return answer in {"y", "yes"}


def _run_verify(db_path: Path, *, verbose: bool) -> int:
    _log(verbose, "")
    _log(verbose, "=== Post-import verify: reverse_geocode ===")
    try:
        hit = reverse_geocode(db_path, VERIFY_LAT, VERIFY_LON)
        _print_json(hit)
        if hit is None:
            print(
                "WARNING: reverse_geocode returned null "
                f"(no city/town/village within search radius of {VERIFY_LAT},{VERIFY_LON}).",
                file=sys.stderr,
            )
            # Still try nearby — DB may have hospitals even if settlements are sparse.
    except Exception as exc:
        print(
            f"ERROR: reverse_geocode failed.\n"
            f"Reason: {type(exc).__name__}: {exc}\n"
            f"DB path: {db_path.resolve()}",
            file=sys.stderr,
        )
        if verbose:
            traceback.print_exc()
        return 1

    _log(verbose, "")
    _log(verbose, "=== Post-import verify: nearby hospitals ===")
    try:
        results = find_nearby(
            db_path,
            VERIFY_LAT,
            VERIFY_LON,
            5000,
            feature_type="hospital",
            limit=20,
        )
        _print_json(results)
        if not results:
            print(
                "WARNING: no hospitals within 5000m of "
                f"{VERIFY_LAT},{VERIFY_LON}. Try a larger radius or another type.",
                file=sys.stderr,
            )
    except Exception as exc:
        print(
            f"ERROR: nearby query failed.\n"
            f"Reason: {type(exc).__name__}: {exc}\n"
            f"DB path: {db_path.resolve()}",
            file=sys.stderr,
        )
        if verbose:
            traceback.print_exc()
        return 1
    return 0


def _cmd_import(args: argparse.Namespace) -> int:
    verbose = not args.quiet
    cwd = Path.cwd()
    requested = expand_user_path(args.pbf)
    output = expand_user_path(args.output)

    _log(verbose, f"cwd:              {cwd}")
    _log(verbose, f"input PBF (arg):  {args.pbf}")
    _log(verbose, f"input PBF (exp):  {requested}")
    _log(verbose, f"output SQLite:    {output}")

    try:
        pbf = resolve_pbf_path(requested, auto_discover=not args.no_discover)
    except FileNotFoundError as exc:
        print(f"ERROR: could not locate PBF file.\n{exc}", file=sys.stderr)
        _log(verbose, "")
        _log(verbose, "Searching common locations anyway...")
        hits = search_osm_pbf(requested.name)
        if hits:
            _log(verbose, "Found these .osm.pbf / .pbf files:")
            for hit in hits:
                _log(verbose, f"  - {hit}")
            _log(verbose, "")
            _log(verbose, "Retry with one of those absolute paths, e.g.:")
            _log(verbose, f'  python -m osm_offline import "{hits[0]}" -o "{output}" --yes')
        return 2

    _log(verbose, f"resolved PBF:     {pbf}")
    _log(verbose, f"resolved output:  {output if output.is_absolute() else (cwd / output)}")
    if str(pbf) != str(requested.resolve() if requested.exists() else requested):
        _log(
            verbose,
            f"NOTE: requested path was missing; auto-discovered:\n  {pbf}",
        )

    out_abs = output if output.is_absolute() else (cwd / output)
    if out_abs.exists() and not args.append:
        if not _confirm_overwrite(out_abs, assume_yes=args.yes):
            print("Import cancelled (existing SQLite not overwritten).", file=sys.stderr)
            return 3

    try:
        stats = import_pbf_to_sqlite(
            pbf,
            output,
            replace=not args.append,
            flush_every=args.flush_every,
            verbose=verbose,
        )
    except FileNotFoundError as exc:
        print(f"ERROR: file not found during import.\nReason: {exc}", file=sys.stderr)
        return 2
    except ImportError as exc:
        print(
            f"ERROR: missing dependency.\nReason: {exc}\n"
            "Fix: pip install -r requirements.txt",
            file=sys.stderr,
        )
        return 4
    except Exception as exc:
        print(
            f"ERROR: import failed.\nReason: {type(exc).__name__}: {exc}",
            file=sys.stderr,
        )
        if verbose:
            traceback.print_exc()
        return 1

    _print_json(stats)
    _log(verbose, "Import succeeded.")

    if args.no_verify:
        return 0

    db_path = Path(stats["db_path"])
    return _run_verify(db_path, verbose=verbose)


def main(argv: Optional[list[str]] = None) -> int:
    # Prefer UTF-8 on Windows consoles so OSM names don't crash printing.
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    except Exception:
        pass

    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        if args.command == "types":
            if args.json:
                print(json.dumps(list(FEATURE_TYPES), indent=2))
            else:
                for t in FEATURE_TYPES:
                    print(t)
            return 0

        if args.command == "find-pbf":
            hits = search_osm_pbf(args.name)
            if not hits:
                print("No .osm.pbf files found in common search locations.")
                return 1
            for hit in hits:
                print(hit)
            return 0

        if args.command == "import":
            return _cmd_import(args)

        if args.command == "nearby":
            db = expand_user_path(args.db)
            if not db.is_file():
                print(
                    f"ERROR: SQLite DB not found.\n"
                    f"cwd: {Path.cwd()}\n"
                    f"requested: {args.db}\n"
                    f"resolved: {db if db.is_absolute() else (Path.cwd() / db)}",
                    file=sys.stderr,
                )
                return 2
            results = find_nearby(
                db,
                args.lat,
                args.lon,
                args.radius,
                feature_type=args.type,
                limit=args.limit,
            )
            _print_json(results)
            return 0

        if args.command == "reverse":
            db = expand_user_path(args.db)
            if not db.is_file():
                print(
                    f"ERROR: SQLite DB not found.\n"
                    f"cwd: {Path.cwd()}\n"
                    f"requested: {args.db}\n"
                    f"resolved: {db if db.is_absolute() else (Path.cwd() / db)}",
                    file=sys.stderr,
                )
                return 2
            hit = reverse_geocode(
                db,
                args.lat,
                args.lon,
                max_radius_meters=args.max_radius,
            )
            _print_json(hit)
            return 0

        parser.print_help()
        return 1
    except Exception as exc:
        print(
            f"ERROR: unexpected failure in '{getattr(args, 'command', '?')}'.\n"
            f"Reason: {type(exc).__name__}: {exc}",
            file=sys.stderr,
        )
        traceback.print_exc()
        return 1


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
