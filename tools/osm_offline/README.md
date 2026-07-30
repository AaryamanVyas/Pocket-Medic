# Offline OSM → SQLite (Pocket Medic)

Convert a regional OpenStreetMap `.osm.pbf` extract into a **local SQLite
database** that the Flutter survival app can ship and query with **zero
network access**.

No Overpass, Nominatim, Google Maps, or other online APIs.

---

## What you get

| Feature types stored | Examples |
|---|---|
| Emergency / services | hospital, clinic, pharmacy, police, fire_station |
| Shelter | campsite, wilderness_hut, shelter |
| Water | drinking_water, spring, river, stream, lake, pond, waterfall |
| Settlements | village, town, city |
| Movement / terrain | road, hiking_trail, peak, cave, forest |

Every row stores: `id`, `name`, `type`, `latitude`, `longitude`, `tags_json`
(plus `osm_id` / `osm_type` for provenance).

Ways (rivers, roads, forests, …) are stored as a **centroid point** so the
mobile app can do simple nearest-point search offline.

---

## Project layout (every file explained)

```
tools/osm_offline/
├── README.md                 ← this file
├── requirements.txt          ← pip dependencies (pyosmium)
├── pyproject.toml            ← installable package metadata + console script
├── .gitignore                ← ignore large PBF/SQLite + venv junk
├── data/                     ← put your .osm.pbf + output .sqlite here (gitignored)
├── scripts/
│   ├── import_pbf.py         ← convenience CLI wrapper for imports
│   └── query_demo.py         ← quick demo of find_nearby + reverse_geocode
└── osm_offline/              ← Python package
    ├── __init__.py           ← public exports
    ├── __main__.py           ← enables: python -m osm_offline …
    ├── cli.py                ← argparse CLI (import / nearby / reverse / types)
    ├── feature_types.py      ← OSM tag → survival type mapping
    ├── geo.py                ← Haversine distance + bbox helpers (offline math)
    ├── schema.py             ← SQLite tables, indexes, R*Tree definition
    ├── db.py                 ← connections + bulk insert into features/R*Tree
    ├── importer.py           ← pyosmium PBF streaming handler + import_pbf_to_sqlite()
    └── query.py              ← find_nearby() + reverse_geocode()
```

### File-by-file

#### `requirements.txt`
Lists runtime deps. Only **pyosmium** is required (C++ Osmium bindings for
fast PBF reading). Everything else is Python stdlib (`sqlite3`, `json`, `math`).

#### `pyproject.toml`
Makes the package installable (`pip install -e .`) and registers the
`osm-offline` console command.

#### `.gitignore`
Keeps huge regional extracts and generated DBs out of git.

#### `osm_offline/feature_types.py`
Single source of truth for:
- which OSM tags map to which survival `type`
- settlement types used by reverse geocoding
- which `highway=*` values count as roads vs hiking trails  
Edit this file when you want to add/remove feature categories.

#### `osm_offline/geo.py`
Pure offline math:
- `haversine_m` — accurate distance in meters
- `bbox_for_radius` — candidate window for SQL/R*Tree filtering
- `centroid` — representative lat/lon for ways

#### `osm_offline/schema.py`
Creates:
- `features` — main table
- B-tree indexes on `type` and `latitude/longitude`
- `features_rtree` — SQLite **R*Tree** virtual table for fast spatial candidate lookup
- `meta` — import provenance (source PBF path, timestamp, counts)

#### `osm_offline/db.py`
Connection helpers, meta get/set, and batched inserts that keep `features`
and `features_rtree` in sync.

#### `osm_offline/importer.py`
Production import path:
1. Open/reset SQLite schema
2. Stream the PBF with `pyosmium` (`locations=True` so ways get coordinates)
3. Classify tags → feature type
4. Buffer + flush rows into SQLite
5. Write import metadata

Public function: **`import_pbf_to_sqlite(pbf_path, db_path)`**

#### `osm_offline/query.py`
Offline query API:

```python
find_nearby(db, latitude, longitude, radius_meters, feature_type=None)
reverse_geocode(db, latitude, longitude)
```

Algorithm:
1. Build a lat/lon bounding box from the radius
2. Pull candidates via R*Tree (B-tree bbox fallback)
3. Exact Haversine filter + sort by distance

#### `osm_offline/cli.py` + `__main__.py`
Command-line entry points for import and queries without writing Python.

#### `scripts/import_pbf.py`
Thin wrapper that defaults to the `import` subcommand.

#### `scripts/query_demo.py`
Prints reverse geocode + a few `find_nearby` samples for demos/QA.

---

## Setup

```bash
cd tools/osm_offline
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# macOS/Linux / WSL
# source .venv/bin/activate

pip install -r requirements.txt
# optional editable install:
pip install -e .
```

### Windows + pyosmium

`pyosmium` often has **no pip wheel on native Windows**. Use one of:

1. **WSL2 (recommended for import):** install Ubuntu, then `pip install -r requirements.txt` inside WSL and run the import there. Copy the resulting `.sqlite` into the Flutter project.
2. **conda-forge:**
   ```bash
   conda create -n osm python=3.11
   conda activate osm
   conda install -c conda-forge pyosmium
   pip install -e .
   ```

Querying an already-built DB (`find_nearby` / `reverse_geocode`) needs **only the Python stdlib** — pyosmium is required solely for PBF import.

Place your extract at e.g.:

```text
tools/osm_offline/data/my-region.osm.pbf
```

---

## Import PBF → SQLite

```bash
python -m osm_offline import data/my-region.osm.pbf -o data/survival.sqlite
```

Or:

```bash
python scripts/import_pbf.py data/my-region.osm.pbf -o data/survival.sqlite
```

Large extracts can take several minutes and may need RAM for Osmium’s
location index (`idx="flex_mem"`). For huge countries, use a smaller
Geofabrik/BBBike regional cut.

---

## Query offline

### Nearest matching features

```bash
python -m osm_offline nearby data/survival.sqlite --lat 28.6139 --lon 77.2090 -r 5000 -t hospital
```

### Reverse geocode (nearest city/town/village)

```bash
python -m osm_offline reverse data/survival.sqlite --lat 28.6139 --lon 77.2090
```

### Python API

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
print(place["name"], place["type"], place["distance_m"])
```

### Demo script

```bash
python scripts/query_demo.py data/survival.sqlite --lat 28.6139 --lon 77.2090
```

---

## SQLite schema (Flutter-ready)

```sql
features(
  id INTEGER PRIMARY KEY,
  osm_id INTEGER NOT NULL,
  osm_type TEXT NOT NULL,          -- node | way | relation
  name TEXT NOT NULL,
  type TEXT NOT NULL,              -- hospital, spring, city, ...
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  tags_json TEXT NOT NULL           -- full OSM tags as JSON
)
```

Ship `survival.sqlite` as a Flutter asset and open it with `sqflite` /
`sqlite3` on-device. Reimplement the same bbox + Haversine pattern in Dart
(or call into a tiny FFI later). The Python `find_nearby` logic is the
reference algorithm.

---

## Notes / limitations

- **Multipolygon relations** are not fully expanded in v1; many lakes/forests
  still appear as closed **ways**, which are imported via centroids.
- **Roads / rivers / trails** are point-approximated (centroid), not full
  polylines. Enough for “nearest road/trail/waterway” survival UX; not a
  turn-by-turn router.
- Always keep guidance conservative in the app UI (especially edible plants /
  drinking water). This DB is location context, not medical or foraging advice.

---

## License note

OpenStreetMap data is © OpenStreetMap contributors, ODbL.
Keep attribution in the app/about screen when shipping extracts.
