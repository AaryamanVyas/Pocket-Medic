"""
Offline OSM → SQLite toolkit for Pocket Medic survival features.

Public API:
  - import_pbf_to_sqlite(pbf_path, db_path)  # requires pyosmium
  - find_nearby(...)
  - reverse_geocode(...)
"""

from .query import find_nearby, reverse_geocode

__all__ = [
    "import_pbf_to_sqlite",
    "find_nearby",
    "reverse_geocode",
]

__version__ = "1.0.0"


def import_pbf_to_sqlite(*args, **kwargs):
    """Lazy wrapper so query tools work even if pyosmium is not installed yet."""
    from .importer import import_pbf_to_sqlite as _import_pbf_to_sqlite

    return _import_pbf_to_sqlite(*args, **kwargs)
