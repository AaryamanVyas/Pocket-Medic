"""
PBF importer using osmiter (pure-Python + protobuf).

Why osmiter (not pyosmium)?
  - Installs with plain `pip` on Windows and Ubuntu/WSL (Python 3.10–3.12)
  - No native C++ toolchain / missing wheels problem
  - Fully offline: only reads a local .osm.pbf file
  - Dependency stack is just `osmiter` → `protobuf` (both on PyPI)

Trade-off: slower than libosmium for country-scale files. For regional
survival extracts this is an acceptable production trade for portability.

Pipeline:
  1. Stream every OSM element from the PBF via osmiter.iter_from_osm
  2. Cache node coordinates in a temporary SQLite table (for way centroids)
  3. Classify tags → survival feature type
  4. Insert matched features into the survival DB + R*Tree
"""

from __future__ import annotations

import sqlite3
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple, Union

from .db import connect, insert_features, set_meta
from .feature_types import classify_tags, normalize_tags, preferred_name
from .geo import centroid, valid_wgs84
from .schema import create_schema, reset_database

try:
    from osmiter import iter_from_osm
except ImportError as exc:  # pragma: no cover
    raise ImportError(
        "osmiter is required. Install with: pip install -r requirements.txt"
    ) from exc


PathLike = Union[str, Path]


class NodeLocationCache:
    """
    Disk-backed node id → (lat, lon) store used while resolving way geometries.

    Using SQLite (not a giant Python dict) keeps memory bounded on large extracts.
    """

    def __init__(self, path: Path) -> None:
        self.path = path
        self.conn = sqlite3.connect(str(path))
        self.conn.execute("PRAGMA journal_mode = OFF")
        self.conn.execute("PRAGMA synchronous = OFF")
        self.conn.execute("PRAGMA temp_store = MEMORY")
        self.conn.execute(
            """
            CREATE TABLE IF NOT EXISTS node_loc (
                id  INTEGER PRIMARY KEY,
                lat REAL NOT NULL,
                lon REAL NOT NULL
            )
            """
        )
        self._buffer: List[Tuple[int, float, float]] = []
        self._buffer_limit = 50_000

    def add(self, node_id: int, lat: float, lon: float) -> None:
        self._buffer.append((node_id, lat, lon))
        if len(self._buffer) >= self._buffer_limit:
            self.flush()

    def flush(self) -> None:
        if not self._buffer:
            return
        self.conn.executemany(
            "INSERT OR REPLACE INTO node_loc(id, lat, lon) VALUES (?, ?, ?)",
            self._buffer,
        )
        self.conn.commit()
        self._buffer.clear()

    def lookup_many(self, node_ids: Iterable[int]) -> List[Tuple[float, float]]:
        ids = list(node_ids)
        if not ids:
            return []
        # Chunk IN queries to stay under SQLite variable limits.
        points: List[Tuple[float, float]] = []
        chunk_size = 900
        for i in range(0, len(ids), chunk_size):
            chunk = ids[i : i + chunk_size]
            placeholders = ",".join("?" for _ in chunk)
            rows = self.conn.execute(
                f"SELECT id, lat, lon FROM node_loc WHERE id IN ({placeholders})",
                chunk,
            ).fetchall()
            by_id = {int(r[0]): (float(r[1]), float(r[2])) for r in rows}
            for nid in chunk:
                if nid in by_id:
                    points.append(by_id[nid])
        return points

    def close(self) -> None:
        self.flush()
        self.conn.close()


def _guess_pbf_format(path: Path) -> str:
    name = path.name.lower()
    if name.endswith(".pbf") or name.endswith(".osm.pbf"):
        return "pbf"
    if name.endswith(".osm.gz") or name.endswith(".gz"):
        return "gz"
    if name.endswith(".osm.bz2") or name.endswith(".bz2"):
        return "bz2"
    if name.endswith(".osm") or name.endswith(".xml"):
        return "xml"
    # Default: treat as PBF (common for regional Geofabrik downloads).
    return "pbf"


def import_pbf_to_sqlite(
    pbf_path: PathLike,
    db_path: PathLike,
    *,
    replace: bool = True,
    flush_every: int = 5000,
    keep_node_cache: bool = False,
) -> Dict[str, Any]:
    """
    Convert an OSM PBF extract into a local SQLite survival database.

    Parameters
    ----------
    pbf_path:
        Path to a regional .osm.pbf file (Geofabrik, BBBike, etc.).
    db_path:
        Output .sqlite / .db path (created if missing).
    replace:
        If True, wipe and recreate tables before import.
    flush_every:
        How many matched features to buffer before writing to SQLite.
    keep_node_cache:
        If True, keep the temporary node-location SQLite file for debugging.
    """
    pbf = Path(pbf_path)
    if not pbf.is_file():
        raise FileNotFoundError(f"PBF not found: {pbf}")

    out = Path(db_path)
    started = time.perf_counter()
    conn = connect(out)

    cache_path = out.with_suffix(out.suffix + ".nodecache")
    node_cache = NodeLocationCache(cache_path)

    stats = {
        "nodes_seen": 0,
        "ways_seen": 0,
        "relations_seen": 0,
        "nodes_kept": 0,
        "ways_kept": 0,
        "skipped_invalid_geom": 0,
        "skipped_unmatched": 0,
    }
    buffer: List[Dict[str, Any]] = []

    def flush_features() -> None:
        if not buffer:
            return
        insert_features(conn, buffer)
        buffer.clear()

    try:
        if replace:
            reset_database(conn)
        else:
            create_schema(conn)

        file_format = _guess_pbf_format(pbf)
        # osmiter streams elements in file order (nodes usually before ways).
        for element in iter_from_osm(str(pbf), file_format=file_format):
            etype = element.get("type")

            if etype == "node":
                stats["nodes_seen"] += 1
                node_id = int(element["id"])
                lat = float(element["lat"])
                lon = float(element["lon"])
                if valid_wgs84(lat, lon):
                    node_cache.add(node_id, lat, lon)
                else:
                    stats["skipped_invalid_geom"] += 1
                    continue

                tags = normalize_tags(element.get("tag"))
                feature_type = classify_tags(tags)
                if feature_type is None:
                    stats["skipped_unmatched"] += 1
                    continue

                buffer.append(
                    {
                        "osm_id": node_id,
                        "osm_type": "node",
                        "name": preferred_name(tags),
                        "type": feature_type,
                        "latitude": lat,
                        "longitude": lon,
                        "tags": tags,
                    }
                )
                stats["nodes_kept"] += 1
                if len(buffer) >= flush_every:
                    flush_features()
                continue

            if etype == "way":
                stats["ways_seen"] += 1
                tags = normalize_tags(element.get("tag"))
                feature_type = classify_tags(tags)
                if feature_type is None:
                    stats["skipped_unmatched"] += 1
                    continue

                # Ensure pending node coords are queryable before lookups.
                node_cache.flush()
                node_ids = [int(n) for n in element.get("nd") or []]
                points = node_cache.lookup_many(node_ids)
                if not points:
                    stats["skipped_invalid_geom"] += 1
                    continue

                lat, lon = centroid(points)
                if not valid_wgs84(lat, lon):
                    stats["skipped_invalid_geom"] += 1
                    continue

                buffer.append(
                    {
                        "osm_id": int(element["id"]),
                        "osm_type": "way",
                        "name": preferred_name(tags),
                        "type": feature_type,
                        "latitude": lat,
                        "longitude": lon,
                        "tags": tags,
                    }
                )
                stats["ways_kept"] += 1
                if len(buffer) >= flush_every:
                    flush_features()
                continue

            if etype == "relation":
                stats["relations_seen"] += 1
                # v1 stores nodes/ways only; multipolygon lakes/forests often
                # still appear as closed ways and are captured above.
                continue

        node_cache.flush()
        flush_features()

        elapsed = time.perf_counter() - started
        count = conn.execute("SELECT COUNT(*) AS c FROM features").fetchone()["c"]

        set_meta(conn, "source_pbf", str(pbf.resolve()))
        set_meta(conn, "imported_at_utc", datetime.now(timezone.utc).isoformat())
        set_meta(conn, "feature_count", str(count))
        set_meta(conn, "importer_version", "2.0.0-osmiter")
        set_meta(conn, "parser", "osmiter")
        conn.commit()

        return {
            "db_path": str(out.resolve()),
            "source_pbf": str(pbf.resolve()),
            "feature_count": int(count),
            "elapsed_seconds": round(elapsed, 2),
            "parser": "osmiter",
            **stats,
        }
    finally:
        node_cache.close()
        conn.close()
        if not keep_node_cache and cache_path.exists():
            try:
                cache_path.unlink()
            except OSError:
                pass
