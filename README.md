# 🎵 Infinite Lofi Engine (Flutter)

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

A generative, multi-layered audio engine built with Flutter. Unlike standard music players that stream large linear files, this engine constructs non-stop, unique Lofi tracks in real-time by mixing synchronized loops and neuro-acoustic layers.

> **Status:** Prototype / V1.0  
> **Target App:** Lyra (Focus & Sleep Assistant)

## 🧠 The Concept

The goal was to solve the issue of repetitive loop fatigue in productivity apps. This engine utilizes a **"Stem Mixing" architecture**:

1.  **The Anchor:** A Drum loop that plays continuously to maintain rhythm.
2.  **The Melody:** Two independent audio players that crossfade between different chord progressions every 15-60 seconds, creating a song that never repeats the exact same pattern.
3.  **The Neuro Layer:** An invisible, user-adjustable layer of Isochronic Tones (Gamma/Alpha/Delta waves) for scientific brainwave entrainment.

## 📱 Features

*   **Gapless Playback:** Seamless looping of OGG assets using `just_audio`.
*   **Generative Algorithm:** Random selection of melody stems with automated linear crossfading.
*   **Multi-Track Synchronization:** Ensures all 4 audio layers start with <50ms drift.
*   **Neuro-Acoustic Mixer:** Independent volume control for brainwave frequencies.
*   **Resource Efficient:** Uses small loop assets (<500kb) instead of streaming large songs (10MB+).

## 🛠 Technical Architecture

The core logic resides in `LofiEngine`, a singleton controller that manages the lifecycle of four concurrent `AudioPlayer` instances.

```dart
// Simplified Logic Flow
Future<void> play() async {
  // 1. Synchronization: Start all stems at the exact same millisecond
  await Future.wait([
    _drumPlayer.play(),
    _neuroPlayer.play(),
    _melodyPlayerA.play(),
    _melodyPlayerB.play(), // Starts silent
  ]);

  // 2. Automation: Start the crossfade timer
  _startCrossfadeCycle();
}
```

Directory Structure
```
lib/
├── engine/
│   └── lofi_engine.dart   # The mixing logic & state management
├── main.dart              # UI & Controls
assets/
├── audio/
├── drums/             # Rhythm loops (80 BPM)
├── chords/            # Melodic loops (80 BPM, Key C)
└── neuro/             # Isochronic Tones (40Hz, 10Hz, etc)
```

🚀 Getting Started

Clone the repository:

git clone https://github.com/YOUR_USERNAME/flutter-generative-lofi-engine.git

Install Dependencies:
flutter pub get

Add Assets:
Note: This repo does not include the raw audio files due to copyright.
Add your own .ogg loops to assets/audio/ ensuring they match the paths in lofi_engine.dart.

Run:
flutter run
(Note: Run on a physical device. Simulators often have audio latency issues.)

👨‍💻 Author
SK