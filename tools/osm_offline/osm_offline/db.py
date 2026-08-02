"""
SQLite connection helpers and bulk insert utilities.
"""

from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Sequence, Union

from .schema import create_schema

PathLike = Union[str, Path]
ConnOrPath = Union[sqlite3.Connection, PathLike]


def connect(db_path: PathLike) -> sqlite3.Connection:
    """Open (or create) the SQLite database with sensible defaults."""
    path = Path(db_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


@contextmanager
def open_db(db: ConnOrPath) -> Iterator[sqlite3.Connection]:
    """
    Yield a connection. If `db` is already a Connection, do not close it.
    If `db` is a path, open and close automatically.
    """
    if isinstance(db, sqlite3.Connection):
        yield db
        return
    conn = connect(db)
    try:
        yield conn
    finally:
        conn.close()


def ensure_schema(conn: sqlite3.Connection) -> None:
    required = {"features", "features_rtree", "meta"}
    rows = conn.execute("SELECT name FROM sqlite_master WHERE type IN ('table', 'view')").fetchall()
    existing = {r["name"] for r in rows}
    if not required.issubset(existing):
        create_schema(conn)


def set_meta(conn: sqlite3.Connection, key: str, value: str) -> None:
    conn.execute(
        """
        INSERT INTO meta(key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        """,
        (key, value),
    )


def get_meta(conn: sqlite3.Connection, key: str) -> Optional[str]:
    row = conn.execute("SELECT value FROM meta WHERE key = ?", (key,)).fetchone()
    return None if row is None else str(row["value"])


def insert_features(
    conn: sqlite3.Connection,
    rows: Sequence[Dict[str, Any]],
    *,
    batch_size: int = 2000,
) -> int:
    """
    Bulk-insert feature dicts and mirror them into the R*Tree.

    Each row must contain:
      osm_id, osm_type, name, type, latitude, longitude, tags (dict or JSON str)
    Optional:
      geometry (list of [lat, lon] pairs for ways)
    """
    if not rows:
        return 0

    ensure_schema(conn)

    inserted = 0
    buffer: List[Dict[str, Any]] = []

    def flush() -> None:
        nonlocal inserted
        if not buffer:
            return
        feature_payload = []
        for item in buffer:
            tags = item["tags"]
            if isinstance(tags, dict):
                tags_json = json.dumps(tags, ensure_ascii=False, separators=(",", ":"))
            else:
                tags_json = str(tags)
            geometry = item.get("geometry")
            geometry_json = json.dumps(geometry, separators=(",", ":")) if geometry else None
            feature_payload.append(
                (
                    int(item["osm_id"]),
                    str(item["osm_type"]),
                    str(item.get("name") or ""),
                    str(item["type"]),
                    float(item["latitude"]),
                    float(item["longitude"]),
                    tags_json,
                    geometry_json,
                )
            )

        before = conn.total_changes
        conn.executemany(
            """
            INSERT OR IGNORE INTO features
                (osm_id, osm_type, name, type, latitude, longitude, tags_json, geometry_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            feature_payload,
        )
        # Re-query inserted ids for this batch (IGNORE means some may be skipped).
        # Faster approach: insert returning isn't portable on older SQLite;
        # instead sync rtree for rows missing from rtree.
        conn.execute(
            """
            INSERT INTO features_rtree (id, min_lat, max_lat, min_lon, max_lon)
            SELECT f.id, f.latitude, f.latitude, f.longitude, f.longitude
            FROM features f
            LEFT JOIN features_rtree r ON r.id = f.id
            WHERE r.id IS NULL
            """
        )
        inserted += max(conn.total_changes - before, 0)
        buffer.clear()

    for row in rows:
        buffer.append(row)
        if len(buffer) >= batch_size:
            flush()
    flush()
    conn.commit()
    return inserted
