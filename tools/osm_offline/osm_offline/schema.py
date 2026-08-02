"""
SQLite schema for offline survival features.

Design choices:
  - One `features` table for all OSM objects.
  - Nodes store a single point (latitude/longitude).
  - Ways store their centroid for fast bbox queries PLUS the full polyline
    geometry in `geometry_json` so Flutter can render trail lines on the map.
  - SQLite R*Tree virtual table (`features_rtree`) accelerates bbox candidate
    lookup for find_nearby / reverse_geocode — fully offline, no SpatiaLite.
  - `tags_json` keeps the original OSM tags for the Flutter UI / AI prompts.
"""

from __future__ import annotations

import sqlite3

SCHEMA_SQL = """
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS features (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    osm_id        INTEGER NOT NULL,
    osm_type      TEXT NOT NULL CHECK (osm_type IN ('node', 'way', 'relation')),
    name          TEXT NOT NULL DEFAULT '',
    type          TEXT NOT NULL,
    latitude      REAL NOT NULL,
    longitude     REAL NOT NULL,
    tags_json     TEXT NOT NULL DEFAULT '{}',
    geometry_json TEXT DEFAULT NULL,
    UNIQUE (osm_type, osm_id)
);

CREATE INDEX IF NOT EXISTS idx_features_type
    ON features(type);

CREATE INDEX IF NOT EXISTS idx_features_lat_lon
    ON features(latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_features_type_lat_lon
    ON features(type, latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_features_settlement
    ON features(type)
    WHERE type IN ('city', 'town', 'village');

-- R*Tree: each feature is a degenerate rectangle (point).
CREATE VIRTUAL TABLE IF NOT EXISTS features_rtree USING rtree(
    id,          -- matches features.id
    min_lat,
    max_lat,
    min_lon,
    max_lon
);
"""


def create_schema(conn: sqlite3.Connection) -> None:
    """Create tables, indexes, and R*Tree if they do not exist."""
    conn.executescript(SCHEMA_SQL)
    conn.commit()


def reset_database(conn: sqlite3.Connection) -> None:
    """Drop and recreate schema (used for clean re-imports)."""
    conn.executescript(
        """
        DROP TABLE IF EXISTS features_rtree;
        DROP TABLE IF EXISTS features;
        DROP TABLE IF EXISTS meta;
        """
    )
    conn.commit()
    create_schema(conn)
