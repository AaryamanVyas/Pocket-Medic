"""
Offline query API used by tooling (and later mirrored in Flutter/sqflite).

No network calls. Distance uses Haversine; candidate filtering uses the
SQLite R*Tree index when available, with a B-tree bbox fallback.
"""

from __future__ import annotations

import json
import sqlite3
from typing import Any, Dict, List, Optional, Union

from .db import ConnOrPath, open_db
from .feature_types import FEATURE_TYPES, SETTLEMENT_TYPES
from .geo import bbox_for_radius, haversine_m, valid_wgs84


def find_nearby(
    db: ConnOrPath,
    latitude: float,
    longitude: float,
    radius_meters: float,
    feature_type: Optional[str] = None,
    *,
    limit: int = 50,
) -> List[Dict[str, Any]]:
    """
    Return survival features within `radius_meters` of (latitude, longitude),
    sorted nearest-first.

    Parameters
    ----------
    db:
        Path to the SQLite file, or an open sqlite3.Connection.
    latitude, longitude:
        Query point in WGS84.
    radius_meters:
        Search radius in meters.
    feature_type:
        Optional filter, e.g. "hospital", "spring", "hiking_trail".
        If None, all types are considered.
    limit:
        Max number of results after distance filtering.

    Returns
    -------
    List of dicts:
      id, osm_id, osm_type, name, type, latitude, longitude, tags, distance_m
    """
    if not valid_wgs84(latitude, longitude):
        raise ValueError("latitude/longitude out of WGS84 range")
    if radius_meters <= 0:
        raise ValueError("radius_meters must be > 0")
    if feature_type is not None and feature_type not in FEATURE_TYPES:
        raise ValueError(
            f"Unknown feature_type '{feature_type}'. "
            f"Expected one of: {', '.join(FEATURE_TYPES)}"
        )

    min_lat, max_lat, min_lon, max_lon = bbox_for_radius(
        latitude, longitude, radius_meters
    )

    with open_db(db) as conn:
        rows = _candidate_rows(
            conn,
            min_lat=min_lat,
            max_lat=max_lat,
            min_lon=min_lon,
            max_lon=max_lon,
            feature_type=feature_type,
        )

    results: List[Dict[str, Any]] = []
    for row in rows:
        dist = haversine_m(latitude, longitude, row["latitude"], row["longitude"])
        if dist > radius_meters:
            continue
        results.append(_row_to_feature(row, distance_m=dist))

    results.sort(key=lambda item: item["distance_m"])
    return results[: max(limit, 0)]


def reverse_geocode(
    db: ConnOrPath,
    latitude: float,
    longitude: float,
    *,
    max_radius_meters: float = 50_000.0,
) -> Optional[Dict[str, Any]]:
    """
    Return the nearest city, town, or village to the given coordinates.

    Preference order when distances are similar is city > town > village
    only as a soft tie-break; primary sort is still distance.

    Returns None if no settlement exists within max_radius_meters.
    """
    if not valid_wgs84(latitude, longitude):
        raise ValueError("latitude/longitude out of WGS84 range")

    # Progressive search radii — avoids scanning huge bboxes for dense regions.
    for radius in (2_000.0, 5_000.0, 15_000.0, max_radius_meters):
        candidates = find_nearby(
            db,
            latitude,
            longitude,
            radius,
            feature_type=None,
            limit=200,
        )
        settlements = [c for c in candidates if c["type"] in SETTLEMENT_TYPES]
        if not settlements:
            continue

        # Soft rank: prefer larger settlements on near-ties (< 500 m).
        rank = {"city": 0, "town": 1, "village": 2}

        def sort_key(item: Dict[str, Any]):
            return (item["distance_m"], rank.get(item["type"], 9))

        settlements.sort(key=sort_key)
        return settlements[0]

    return None


def _candidate_rows(
    conn: sqlite3.Connection,
    *,
    min_lat: float,
    max_lat: float,
    min_lon: float,
    max_lon: float,
    feature_type: Optional[str],
) -> List[sqlite3.Row]:
    """Pull bbox candidates via R*Tree, with SQL bbox fallback."""
    # R*Tree overlap: rect.min <= query.max AND rect.max >= query.min
    rtree_params: List[Any] = [max_lat, min_lat, max_lon, min_lon]
    rtree_sql = """
        SELECT f.id, f.osm_id, f.osm_type, f.name, f.type,
               f.latitude, f.longitude, f.tags_json
        FROM features_rtree r
        JOIN features f ON f.id = r.id
        WHERE r.min_lat <= ? AND r.max_lat >= ?
          AND r.min_lon <= ? AND r.max_lon >= ?
    """
    if feature_type is not None:
        rtree_sql += " AND f.type = ?"
        rtree_params.append(feature_type)

    try:
        rows = conn.execute(rtree_sql, rtree_params).fetchall()
        if rows or _rtree_has_rows(conn):
            return rows
    except sqlite3.Error:
        pass

    # Fallback: plain B-tree indexes on lat/lon.
    fallback_params: List[Any] = [min_lat, max_lat, min_lon, max_lon]
    fallback_sql = """
        SELECT id, osm_id, osm_type, name, type, latitude, longitude, tags_json
        FROM features
        WHERE latitude BETWEEN ? AND ?
          AND longitude BETWEEN ? AND ?
    """
    if feature_type is not None:
        fallback_sql += " AND type = ?"
        fallback_params.append(feature_type)
    return conn.execute(fallback_sql, fallback_params).fetchall()


def _rtree_has_rows(conn: sqlite3.Connection) -> bool:
    try:
        row = conn.execute("SELECT 1 FROM features_rtree LIMIT 1").fetchone()
        return row is not None
    except sqlite3.Error:
        return False


def _row_to_feature(row: sqlite3.Row, *, distance_m: float) -> Dict[str, Any]:
    tags_raw = row["tags_json"]
    try:
        tags = json.loads(tags_raw) if tags_raw else {}
    except json.JSONDecodeError:
        tags = {"_raw_tags_json": tags_raw}

    return {
        "id": int(row["id"]),
        "osm_id": int(row["osm_id"]),
        "osm_type": str(row["osm_type"]),
        "name": str(row["name"] or ""),
        "type": str(row["type"]),
        "latitude": float(row["latitude"]),
        "longitude": float(row["longitude"]),
        "tags": tags,
        "distance_m": round(float(distance_m), 2),
    }
