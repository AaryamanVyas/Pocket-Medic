"""Lightweight offline unit tests (no PBF required)."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

from osm_offline.feature_types import classify_tags
from osm_offline.geo import bbox_for_radius, haversine_m
from osm_offline.query import find_nearby, reverse_geocode
from osm_offline.schema import create_schema


class GeoTests(unittest.TestCase):
    def test_haversine_zero(self):
        self.assertEqual(haversine_m(0, 0, 0, 0), 0.0)

    def test_bbox_contains_point(self):
        min_lat, max_lat, min_lon, max_lon = bbox_for_radius(28.6, 77.2, 1000)
        self.assertLess(min_lat, 28.6)
        self.assertGreater(max_lat, 28.6)
        self.assertLess(min_lon, 77.2)
        self.assertGreater(max_lon, 77.2)


class ClassifyTests(unittest.TestCase):
    def test_hospital(self):
        self.assertEqual(classify_tags({"amenity": "hospital"}), "hospital")

    def test_spring(self):
        self.assertEqual(classify_tags({"natural": "spring"}), "spring")

    def test_trail(self):
        self.assertEqual(classify_tags({"highway": "path"}), "trail")

    def test_ignore(self):
        self.assertIsNone(classify_tags({"amenity": "cafe"}))


class QueryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmp.name) / "test.sqlite"
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        create_schema(self.conn)
        rows = [
            (1, "node", "City A", "city", 28.61, 77.20, "{}"),
            (2, "node", "Town B", "town", 28.62, 77.21, "{}"),
            (3, "node", "Hospital X", "hospital", 28.611, 77.201, "{}"),
            (4, "node", "Far Clinic", "clinic", 29.5, 78.5, "{}"),
        ]
        self.conn.executemany(
            """
            INSERT INTO features (osm_id, osm_type, name, type, latitude, longitude, tags_json)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            rows,
        )
        self.conn.execute(
            """
            INSERT INTO features_rtree (id, min_lat, max_lat, min_lon, max_lon)
            SELECT id, latitude, latitude, longitude, longitude FROM features
            """
        )
        self.conn.commit()
        self.conn.close()

    def tearDown(self):
        self.tmp.cleanup()

    def test_find_nearby_hospital(self):
        hits = find_nearby(self.db_path, 28.61, 77.20, 2000, feature_type="hospital")
        self.assertEqual(len(hits), 1)
        self.assertEqual(hits[0]["name"], "Hospital X")

    def test_reverse_geocode(self):
        place = reverse_geocode(self.db_path, 28.6105, 77.2005)
        self.assertIsNotNone(place)
        assert place is not None
        self.assertIn(place["type"], {"city", "town", "village"})


class OsmiterImportSmokeTests(unittest.TestCase):
    def test_osmiter_importable(self):
        import osmiter  # noqa: F401

        from osm_offline.importer import import_pbf_to_sqlite

        self.assertTrue(callable(import_pbf_to_sqlite))


class ImporterTests(unittest.TestCase):
    def test_import_small_osm(self):
        import tempfile
        from pathlib import Path
        from osm_offline.importer import import_pbf_to_sqlite
        
        osm_xml = """<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="test">
  <node id="1" lat="28.61" lon="77.20" version="1" timestamp="2023-01-01T00:00:00Z">
    <tag k="amenity" v="hospital"/>
    <tag k="name" v="Test Hospital"/>
  </node>
</osm>
"""
        with tempfile.TemporaryDirectory() as tmpdir:
            pbf_path = Path(tmpdir) / "test.osm"
            pbf_path.write_text(osm_xml, encoding="utf-8")
            
            db_path = Path(tmpdir) / "survival.sqlite"
            
            # The database is completely missing, ensure it gets created and import succeeds.
            stats = import_pbf_to_sqlite(pbf_path, db_path, replace=True)
            self.assertEqual(stats["nodes_kept"], 1)
            
            conn = sqlite3.connect(db_path)
            rows = conn.execute("SELECT name FROM sqlite_master WHERE type IN ('table', 'view')").fetchall()
            tables = {r[0] for r in rows}
            self.assertIn("features", tables)
            self.assertIn("features_rtree", tables)
            
            count = conn.execute("SELECT COUNT(*) FROM features").fetchone()[0]
            self.assertEqual(count, 1)
            
            rtree_count = conn.execute("SELECT COUNT(*) FROM features_rtree").fetchone()[0]
            self.assertEqual(rtree_count, 1)
            conn.close()

            # Now test append mode where features_rtree is intentionally dropped to simulate the crash scenario
            conn = sqlite3.connect(db_path)
            conn.execute("DROP TABLE IF EXISTS features_rtree")
            conn.commit()
            conn.close()

            # Importing again with replace=False should recreate features_rtree and not crash
            stats2 = import_pbf_to_sqlite(pbf_path, db_path, replace=False)
            self.assertEqual(stats2["nodes_kept"], 1)

            conn = sqlite3.connect(db_path)
            rows = conn.execute("SELECT name FROM sqlite_master WHERE type IN ('table', 'view')").fetchall()
            tables = {r[0] for r in rows}
            self.assertIn("features_rtree", tables)
            conn.close()

if __name__ == "__main__":
    unittest.main()
