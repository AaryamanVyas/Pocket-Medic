"""
PBF importer using pyosmium.

Reads an .osm.pbf file once, classifies nodes/ways into survival feature types,
and writes representative points into SQLite.

Ways (rivers, roads, forests, lakes, …) are stored as the centroid of their
node locations so the Flutter app can run simple nearest-point queries offline.
"""

from __future__ import annotations

import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

from .db import connect, insert_features, set_meta
from .feature_types import classify_tags, iter_tag_dict, preferred_name
from .geo import centroid, valid_wgs84
from .schema import reset_database

try:
    import osmium
except ImportError as exc:  # pragma: no cover
    raise ImportError(
        "pyosmium is required. Install with: pip install -r requirements.txt"
    ) from exc


PathLike = Union[str, Path]


class SurvivalFeatureHandler(osmium.SimpleHandler):
    """
    Streaming OSM handler. Collects matching features in memory batches and
    periodically flushes them to SQLite to bound RAM usage.
    """

    def __init__(self, conn, *, flush_every: int = 5000) -> None:
        super().__init__()
        self.conn = conn
        self.flush_every = flush_every
        self._buffer: List[Dict[str, Any]] = []
        self.stats = {
            "nodes_seen": 0,
            "ways_seen": 0,
            "nodes_kept": 0,
            "ways_kept": 0,
            "skipped_invalid_geom": 0,
        }

    def node(self, n) -> None:
        self.stats["nodes_seen"] += 1
        if not n.location.valid():
            return
        tags = iter_tag_dict(n.tags)
        feature_type = classify_tags(tags)
        if feature_type is None:
            return

        lat = float(n.location.lat)
        lon = float(n.location.lon)
        if not valid_wgs84(lat, lon):
            self.stats["skipped_invalid_geom"] += 1
            return

        self._buffer.append(
            {
                "osm_id": int(n.id),
                "osm_type": "node",
                "name": preferred_name(tags),
                "type": feature_type,
                "latitude": lat,
                "longitude": lon,
                "tags": tags,
            }
        )
        self.stats["nodes_kept"] += 1
        self._maybe_flush()

    def way(self, w) -> None:
        self.stats["ways_seen"] += 1
        tags = iter_tag_dict(w.tags)
        feature_type = classify_tags(tags)
        if feature_type is None:
            return

        points = []
        # locations=True on apply_file makes node refs resolvable.
        for node_ref in w.nodes:
            if not node_ref.location.valid():
                continue
            points.append((float(node_ref.location.lat), float(node_ref.location.lon)))

        if not points:
            self.stats["skipped_invalid_geom"] += 1
            return

        lat, lon = centroid(points)
        if not valid_wgs84(lat, lon):
            self.stats["skipped_invalid_geom"] += 1
            return

        self._buffer.append(
            {
                "osm_id": int(w.id),
                "osm_type": "way",
                "name": preferred_name(tags),
                "type": feature_type,
                "latitude": lat,
                "longitude": lon,
                "tags": tags,
            }
        )
        self.stats["ways_kept"] += 1
        self._maybe_flush()

    def _maybe_flush(self) -> None:
        if len(self._buffer) >= self.flush_every:
            self.flush()

    def flush(self) -> None:
        if not self._buffer:
            return
        insert_features(self.conn, self._buffer)
        self._buffer.clear()


def import_pbf_to_sqlite(
    pbf_path: PathLike,
    db_path: PathLike,
    *,
    replace: bool = True,
    flush_every: int = 5000,
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

    Returns
    -------
    dict with import statistics.
    """
    pbf = Path(pbf_path)
    if not pbf.is_file():
        raise FileNotFoundError(f"PBF not found: {pbf}")

    started = time.perf_counter()
    conn = connect(db_path)
    try:
        if replace:
            reset_database(conn)
        else:
            from .schema import create_schema

            create_schema(conn)

        handler = SurvivalFeatureHandler(conn, flush_every=flush_every)
        # locations=True builds a node-location index so ways get coordinates.
        handler.apply_file(str(pbf), locations=True, idx="flex_mem")
        handler.flush()

        elapsed = time.perf_counter() - started
        count = conn.execute("SELECT COUNT(*) AS c FROM features").fetchone()["c"]

        set_meta(conn, "source_pbf", str(pbf.resolve()))
        set_meta(conn, "imported_at_utc", datetime.now(timezone.utc).isoformat())
        set_meta(conn, "feature_count", str(count))
        set_meta(conn, "importer_version", "1.0.0")
        conn.commit()

        return {
            "db_path": str(Path(db_path).resolve()),
            "source_pbf": str(pbf.resolve()),
            "feature_count": int(count),
            "elapsed_seconds": round(elapsed, 2),
            **handler.stats,
        }
    finally:
        conn.close()
