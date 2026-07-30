# Pocket Medic (Round 1 UI Demo)

UI-first Flutter prototype for an offline first-aid triage app.

## What this demo shows

- Home screen with offline-first story
- Symptom text input
- Mock image attach toggle
- Triage output screen with:
  - severity badge
  - likely issue
  - immediate first-aid steps
  - seek-help flag
  - safety disclaimer

## Current status

This is a **UI + mocked logic** base for quick hackathon presentation.
No real model inference is wired yet.

## Next integration step

Replace `MockTriageResponse.fromInput(...)` in `lib/main.dart` with real Gemma/llama.cpp output parsing.
