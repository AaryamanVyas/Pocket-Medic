# Offline OSM → SQLite (Pocket Medic)

Convert a regional OpenStreetMap `.osm.pbf` extract into a **local SQLite
database** that the Flutter survival app can ship and query with **zero
network access**.

No Overpass, Nominatim, Google Maps, or other online APIs.

---

## Why `osmiter` (not `pyosmium`)

| | **osmiter** (chosen) | **pyosmium** (removed) |
|---|---|---|
| Install | Plain `pip` on **Windows + Ubuntu WSL** | Often **no wheel** on Windows / some WSL Pythons |
| Native deps | None (pure Python + `protobuf`) | Needs libosmium C++ bindings |
| Offline PBF read | Yes | Yes |
| Speed | Slower on huge country extracts | Faster |
| Fit for this project | Best portability for hackathon / team laptops | Blocked your build environment |

We chose **osmiter** because the importer must be **production-usable on the machines you actually have**. Portability > raw parse speed for regional survival extracts.

---

## What gets extracted

| Category | `type` values |
|---|---|
| Emergency / services | `hospital`, `clinic`, `pharmacy`, `police`, `fire_station` |
| Shelter | `campsite`, `shelter` |
| Water | `spring`, `river`, `stream`, `lake` |
| Settlements | `village`, `town`, `city` (city kept for reverse geocode) |
| Movement | `road`, `trail` |

Every row stores: `id`, `name`, `type`, `latitude`, `longitude`, `tags_json`
(plus `osm_id` / `osm_type`).

Ways (rivers, roads, trails, lakes, …) are stored as a **centroid point** so
the app can do simple nearest-point search offline. An **R\*Tree** index
(`features_rtree`) speeds candidate lookup.

---

## Project layout

```
tools/osm_offline/
├── README.md
├── requirements.txt          ← osmiter + protobuf (no pyosmium)
├── pyproject.toml
├── .gitignore
├── data/                     ← put .osm.pbf + output .sqlite here
├── scripts/
│   ├── import_pbf.py
│   └── query_demo.py
├── tests/test_offline.py
└── osm_offline/
    ├── __init__.py           ← public exports
    ├── __main__.py           ← python -m osm_offline
    ├── cli.py                ← import / nearby / reverse / types
    ├── feature_types.py      ← OSM tag → survival type mapping
    ├── geo.py                ← Haversine + bbox helpers
    ├── schema.py             ← SQLite + R*Tree schema
    ├── db.py                 ← connections + bulk insert
    ├── importer.py           ← osmiter streaming PBF importer
    └── query.py              ← find_nearby + reverse_geocode
```

### File roles

- **`importer.py`** — streams PBF with `osmiter.iter_from_osm`, caches node
  coordinates in a temporary SQLite file, classifies tags, writes features + R\*Tree.
- **`query.py`** — `find_nearby` / `reverse_geocode` (stdlib + SQLite only).
- **`feature_types.py`** — which OSM tags become which survival types.
- **`schema.py` / `db.py`** — SQLite schema, indexes, R\*Tree sync.
- **`cli.py`** — preserves `import`, `nearby`, `reverse`, `types`.

---

## Setup

```bash
cd tools/osm_offline
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Ubuntu WSL / Linux / macOS
# source .venv/bin/activate

pip install -r requirements.txt
# optional:
pip install -e .
```

Put your extract at:

```text
tools/osm_offline/data/my-region.osm.pbf
```

---

## CLI (unchanged commands)

### Import

```bash
python -m osm_offline import data/my-region.osm.pbf -o data/survival.sqlite
```

### Nearby

```bash
python -m osm_offline nearby data/survival.sqlite --lat 28.6139 --lon 77.2090 -r 5000 -t hospital
```

### Reverse geocode

```bash
python -m osm_offline reverse data/survival.sqlite --lat 28.6139 --lon 77.2090
```

### List types

```bash
python -m osm_offline types
```

---

## Python API

```python
from osm_offline import import_pbf_to_sqlite, find_nearby, reverse_geocode

import_pbf_to_sqlite("data/my-region.osm.pbf", "data/survival.sqlite")

hospitals = find_nearby(
    "data/survival.sqlite",
    latitude=28.6139,
    longitude=77.2090,
    radius_meters=5000,
    feature_type="hospital",
)

place = reverse_geocode("data/survival.sqlite", 28.6139, 77.2090)
```

---

## Tests

```bash
python -m unittest tests.test_offline -v
```

---

## Notes

- Import is **fully offline** once the `.osm.pbf` is on disk.
- Large country extracts will be slower with osmiter than with libosmium —
  prefer a **regional** Geofabrik/BBBike cut for survival demos.
- Multipolygon relations are skipped in v1; many lakes still appear as closed
  **ways** and are imported via centroids.
- OSM data © OpenStreetMap contributors (ODbL) — keep attribution in the app.
