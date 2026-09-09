# LifeWord

An iOS app for learning English vocabulary through interactive, photorealistic scenes — built for Ukrainian speakers, with Clean Architecture and SwiftUI.

## What it does

Instead of flat word lists, LifeWord teaches vocabulary through everyday scenes (a bedroom, a bathroom, a kitchen). Each scene is a real photo with tappable hotspots on individual objects — tap the toilet, hear "toilet," see the Ukrainian translation and phonetic transcription. Every word also comes with example sentences used in fill-in-the-blank exercises, each with distractor options pulled from the same category.

## Architecture

- **Clean Architecture / MVVM** — Domain, Data, and Presentation layers are separated; view models depend on use cases, not on the data layer directly.
- **SwiftUI** throughout, including a custom `GeometryReader`-based layout system that maps normalized (0–1) hotspot coordinates onto the actual displayed image size, so the same scene photo works correctly across every device size.
- **JSON-driven content model** — categories, words, sentences, and scene hotspots are all defined in a single `content.json`, decoded via `JSONDecoder` into the domain layer. Adding a new vocabulary category requires no code changes, only new content.

## Content pipeline

Content for each category (currently: Bedroom, Bathroom, Bathroom 2, Kitchen, Kitchen 2 — ~250 words and ~500 example sentences so far) is authored, validated, and merged through a small set of Python scripts:

- Every word/sentence set is validated programmatically before merging — checking that each sentence's target word actually appears in its tokenized form, that answer options are unique, and that no id collides with existing content.
- A custom **in-app hotspot marking tool** (SwiftUI, `#if DEBUG`-gated so it never ships to production) lets me tap directly on a scene photo, pick the corresponding word from a searchable list, and get back ready-to-paste `{wordId, x, y}` JSON on the clipboard — turning scene mapping into a five-minute task per category instead of manual coordinate guessing.

## Audio pipeline

Every word and sentence needs its own pronunciation clip — around 150 audio files per category (word-level + sentence-level). Recording or manually generating each one individually was taking roughly 3 hours per category.

I built a Python batch-generation script against the **ElevenLabs Text-to-Speech API** that:
- takes the full word/sentence list for a category and generates every audio file in one run,
- skips files that already exist, so an interrupted run resumes safely instead of restarting,
- reports and retries only the files that failed.

This cut audio production time from ~3 hours to ~3 minutes per category.

## Tech stack

Swift, SwiftUI, Clean Architecture, MVVM, Firebase, SwiftData, WidgetKit · Python (content generation & validation, ElevenLabs API automation) · JSON-based content schema

## Status

Actively in development — current focus is core logic, content pipeline, and screen flows before visual polish.
