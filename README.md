# Pocket Medic

Offline-first field assistance app for survival and first-aid guidance.

## Features

- **Ask offline** — Topic-based guidance (Medical, Food, Water, Wildlife, Locate) with on-device AI (Gemma 4) and fallback mock responses
- **Mushroom classifier** — TFLite on-device image classification (edible vs poisonous) with confidence scores and uncertainty warnings
- **Offline maps** — flutter_map with OpenStreetMap tiles, nearby POI markers (hospitals, police, water, campsites, trails, villages), compass bearing, and route navigation
- **Trail navigation** — Polyline rendering with snap-to-trail green indicator
- **Text RAG knowledge base** — SQLite FTS5 full-text search over survival/first-aid guides (rashes, bites, insects, animals, cooking, medical)
- **Region management** — Download and manage offline map data for different regions
- **Emergency screen** — Quick access to emergency numbers, nearest hospitals/police with routing
- **History** — Local SQLite history of past queries
- **Compass navigation** — Bearing display on places and emergency screens
- **Voice input** — On-device speech-to-text (speech_to_text v7)

## Architecture

- `lib/main.dart` — App entry, permission/Gemma init
- `lib/theme/app_tokens.dart` — Design tokens and AskCategory enum
- `lib/models/` — Place, HistoryEntry, MockAskResponse
- `lib/services/` — AiService, ClassifierService, KnowledgeService, OsmService, RegionService, HistoryStore, SettingsService, PermissionService, NavigationService, DatabaseService
- `lib/screens/` — MainShell, MapScreen, AskScreen, AskResult, PlacesScreen, EmergencyScreen, FieldGuides, HistoryScreen, RegionPicker, Settings

## Offline Data

- `assets/mushroom_classifier.tflite` — On-device mushroom classifier model
- `assets/labels.txt` — Class labels (edible, poisonous)
- `assets/knowledge/knowledge_chunks.json` — 15 survival/first-aid knowledge chunks for RAG
- `tools/osm_offline/` — Python tool to build survival.sqlite from OpenStreetMap data

## Training the Mushroom Classifier

1. Open `notebooks/mushroom_classifier.ipynb` in Google Colab
2. Upload the Kaggle dataset (edible-poisonous mushroom sporocarps)
3. Run all cells to train and export the model
4. Replace `assets/mushroom_classifier.tflite` and `assets/labels.txt` with the downloaded files
5. Run `flutter pub get`

## Run

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
dart analyze lib/
```

## CI/CD

GitHub Actions workflow at `.github/workflows/ci.yml` runs:
- `dart analyze lib/`
- `flutter test`
- `flutter build apk --debug`
- `flutter build linux --debug`