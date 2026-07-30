"""
Offline OSM → SQLite toolkit for Pocket Medic survival features.

Public API:
  - import_pbf_to_sqlite(pbf_path, db_path)
  - find_nearby(...)
  - reverse_geocode(...)
"""

from .importer import import_pbf_to_sqlite
from .query import find_nearby, reverse_geocode

__all__ = [
    "import_pbf_to_sqlite",
    "find_nearby",
    "reverse_geocode",
]

__version__ = "2.0.0"
