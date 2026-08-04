# Pocket Medic

**Offline-first field assistance app for survival and first-aid guidance.**

Built for the *AI off the Grid* hackathon. No backend, no cloud, no API keys — everything runs on-device.

[![CI](https://github.com/pocket-medic/Pocket-Medic/actions/workflows/ci.yml/badge.svg)](https://github.com/pocket-medic/Pocket-Medic/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Features

### On-Device AI (Gemma 4)

Full offline LLM powered by Google's Gemma 4 model running via `flutter_gemma` and the LiteRT inference engine. Ask anything about survival, first-aid, foraging, wildlife, or navigation — the model responds with structured JSON (urgency level, actionable steps, escalation advice). Falls back to rule-based responses if the model isn't loaded.

### Mushroom Classifier (TFLite)

On-device image classifier that identifies whether a mushroom is **edible** or **poisonous** from a camera photo or gallery image. Uses a MobileNetV2 model trained on 3,400+ images with float16 quantization. Shows confidence scores and flags uncertain predictions (< 65% confidence).

### Offline Maps & POI

Interactive `flutter_map` with OpenStreetMap tiles. Locates nearby POIs from a local SQLite database — hospitals, clinics, pharmacies, police stations, fire stations, springs, rivers, campsites, shelters, trails, and villages. Color-coded markers with distance labels. Supports filtering by type.

### Compass Navigation

Live compass bearing display on places and emergency screens. Turn-by-turn navigation with straight-line routes, interpolated waypoints, and compass-heading instructions (Head N, Turn left, Continue NE, etc.).

### Snap-to-Trail

Automatically detects when you're near a trail and snaps your position to it. Shows a green "On trail" indicator. Trail polylines render on the map with full geometry.

### Text RAG Knowledge Base

SQLite FTS5 full-text search over 15+ survival and first-aid knowledge chunks covering rashes, bites, insects, animals, cooking, and medical topics. Retrieved context is injected into the AI model's system prompt for more accurate, grounded responses.

### Region Management

Download and switch between offline map regions. Each region contains a full `survival.sqlite` database with POIs and trail geometry. Regions are downloaded from GitHub with retry logic, progress tracking, and SHA-256 checksum verification.

### Storage Management

Dedicated storage screen showing device usage, AI model download/delete (~3 GB), and per-region file sizes with delete controls. Pre-download storage checks prevent failed installs.

### Emergency Screen

One-tap emergency calling (112). Displays nearest hospitals and police stations with compass bearings, distances, and route buttons that open Google Maps.

### Voice Input

On-device speech-to-text via `speech_to_text` v7. Tap the microphone to dictate questions.

### History

Local SQLite history of all past queries with category filtering. Entries store urgency, summary, timestamp, and input type.

### Field Guides

Offline reference checklists for food safety, finding water, wildlife avoidance, getting to help, cuts and bleeding, and burns.

---

## Architecture

```
lib/
├── main.dart                          # App entry, permission/Gemma init
├── theme/
│   └── app_tokens.dart                # Design tokens, AskCategory enum
├── models/
│   ├── ask_response.dart              # MockAskResponse with fromInput()
│   ├── history_entry.dart             # HistoryEntry with SQLite serialization
│   └── place.dart                     # Place with geometry + fromMap()
├── services/
│   ├── ai_service.dart                # Gemma 4 inference + RAG prompt building
│   ├── classifier_service.dart        # TFLite mushroom classification
│   ├── knowledge_service.dart         # FTS5 knowledge base
│   ├── download_service.dart          # HTTP downloads with retry + checksum
│   ├── storage_service.dart           # Disk space detection + file sizes
│   ├── osm_service.dart               # Offline SQLite POI queries + snap-to-trail
│   ├── navigation_service.dart        # Straight-line routing + compass headings
│   ├── region_service.dart            # Region catalog + download management
│   ├── history_store.dart             # In-memory history cache
│   ├── database_service.dart          # SQLite history database
│   ├── settings_service.dart          # SharedPreferences wrapper
│   ├── permission_service.dart        # Runtime permission requests
│   └── logger_service.dart            # Debug-only tag-based logger
└── screens/
    ├── main_shell.dart                # 5-tab NavigationBar + Dashboard
    ├── ask_screen.dart                # Q&A input (text, photo, voice, TFLite)
    ├── ask_result.dart                # Response display (urgency, steps, save)
    ├── map_screen.dart                # Interactive map with markers + polylines
    ├── navigation_screen.dart         # Turn-by-turn navigation overlay
    ├── places_screen.dart             # Nearby places list with compass bearing
    ├── emergency_screen.dart          # Emergency calls + nearest help
    ├── field_guides.dart              # Static survival checklists
    ├── history_screen.dart            # Query history with filters
    ├── region_picker_screen.dart      # Region download manager
    ├── settings_screen.dart           # App settings
    └── storage_management_screen.dart # Storage usage + model/region management
```

### Data Flow

| Flow | Path |
|------|------|
| **AI Query** | `AskScreen` → `AiService.ask()` → `KnowledgeService.retrieve()` (RAG) → `FlutterGemma` (inference) → `AskResultScreen` |
| **Mushroom ID** | `AskScreen` (photo) → `ClassifierService.classify()` → inline result |
| **Map / POIs** | `MapScreen` → `OsmService.findNearby()` → `survival.sqlite` |
| **Navigation** | `MapScreen` → `NavigationScreen` → `NavigationService.buildRoute()` |
| **History** | `AskResultScreen` → `HistoryStore.add()` → `pocket_medic.db` |
| **Regions** | `RegionPickerScreen` → `RegionService` → `DownloadService` → `survival.sqlite` |

---

## Getting Started

### Prerequisites

- Flutter 3.44.8+
- For Android: Android Studio / SDK
- For Linux: `ninja-build`, `libgtk-3-dev`
- For on-device AI: Download `gemma-4-E2B-it.litertlm` (~3 GB)

### Install

```bash
flutter pub get
flutter run
```

### Model Setup

The Gemma 4 model (~3 GB) must be placed in the device's **Downloads** folder:

```
/storage/emulated/0/Download/gemma-4-E2B-it.litertlm
```

Alternatively, download it from the **Storage** screen in-app.

### Map Data

The app ships with a built-in Southern India region. To use custom regions:

```bash
cd tools/osm_offline
python -m osm_offline import your-region.osm.pbf -o survival.sqlite
```

Copy the resulting `survival.sqlite` to the device, or use the region picker to download from GitHub.

---

## Testing

```bash
flutter test                        # Run all 69 tests
dart analyze lib/                   # Static analysis (0 issues)
```

| Test File | Tests |
|-----------|-------|
| `ask_response_test.dart` | 15 — MockAskResponse across all categories |
| `navigation_service_test.dart` | 11 — Routing, distance, compass headings |
| `history_entry_test.dart` | 4 — SQLite round-trip serialization |
| `region_info_test.dart` | 4 — JSON parsing, center coordinates |
| `download_service_test.dart` | 12 — Data classes, retry, checksum, progress |
| `storage_service_test.dart` | 17 — formatBytes, StorageInfo computed properties |
| `widget_test.dart` | 5 — AskCategory labels, HistoryEntry |

---

## Offline Data Pipeline

```
.osm.pbf  →  osm_offline Python tool  →  survival.sqlite (with R*Tree index)
                                              ↓
                                     Device / GitHub download
                                              ↓
                                     OsmService reads at runtime
```

The `tools/osm_offline/` package converts OpenStreetMap PBF extracts into optimized SQLite databases with spatial indexing. It classifies OSM tags into survival-relevant feature types (hospitals, campsites, springs, trails, etc.) and stores trail/river geometry as polyline JSON.

---

## Training the Mushroom Classifier

1. Open `notebooks/mushroom_classifier.ipynb` in Google Colab (free tier)
2. Upload the [Kaggle dataset](https://www.kaggle.com/datasets/over-3000-images-of-edible-and-poisonous-sporocarps) (3,401 images)
3. Run all cells — trains MobileNetV2 with data augmentation, float16 quantization, 25 epochs
4. Download `mushroom_classifier.tflite` and `labels.txt`
5. Replace files in `assets/`
6. Run `flutter pub get`

---

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push/PR to `main`:

| Job | What it does |
|-----|-------------|
| `analyze` | `dart analyze lib/` |
| `test` | `flutter test` |
| `build-apk` | `flutter build apk --debug` |
| `build-linux` | Installs GTK3 + ninja, then `flutter build linux --debug` |

Build jobs depend on analyze + test passing first.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_gemma` + `flutter_gemma_litertlm` | Gemma 4 LLM inference |
| `tflite_flutter` | TFLite model inference (mushroom classifier) |
| `flutter_map` + `latlong2` | Map rendering with OpenStreetMap |
| `sqflite` | SQLite database (history, POIs, knowledge) |
| `geolocator` | GPS location services |
| `speech_to_text` | On-device speech-to-text |
| `image_picker` | Camera / gallery image selection |
| `permission_handler` | Runtime permission requests |
| `shared_preferences` | Key-value persistence |
| `path_provider` | App directory paths |
| `url_launcher` | Phone calls, map URIs |
| `http` | HTTP client for downloads |
| `crypto` | SHA-256 checksum verification |
| `image` | Image decoding / resizing for TFLite |

---

## License

MIT
