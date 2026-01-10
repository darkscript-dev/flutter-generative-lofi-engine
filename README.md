# 🎧 Infinite Lofi Engine (Flutter)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Status](https://img.shields.io/badge/Status-Prototype-green?style=for-the-badge)

> **A high-performance generative audio engine that creates non-stop, evolving Lofi music mixed with isochronic tones for cognitive optimization.**

---

## 📱 Project Overview

Unlike standard music players that stream large, linear MP3 files, the **Infinite Lofi Engine** is a real-time audio mixer. It constructs music on the fly by synchronizing separate audio "stems" (Drums, Melodies, and Atmosphere).

This architecture allows for:
1.  **Infinite Playback:** By randomly crossfading melody loops over a constant drum anchor, the music never repeats effectively.
2.  **Zero-Latency Looping:** Uses OGG Vorbis assets for seamless, gapless playback on Android/iOS.
3.  **Brainwave Entrainment:** A dedicated, independent audio layer injects Isochronic Tones to help the user Focus, Relax, or Sleep.

---

## 🧠 The "Neuro" Logic (Brain Optimization)

This engine isn't just for music; it's a productivity tool. It uses a dedicated `NeuroPlayer` to overlay subtle isochronic pulses.

| Mode | Frequency | Target State |
| :--- | :--- | :--- |
| **Focus** | 40Hz (Gamma) | Peak concentration, problem solving, coding. |
| **Relax** | 10Hz (Alpha) | Flow state, reading, light work. |
| **Sleep** | 2Hz (Delta) | Deep restorative sleep induction. |

*The engine allows independent volume mixing of this layer, giving the user full control over the intensity of the entrainment.*

---

## ⚙️ Technical Architecture

The core logic resides in `LofiEngine`, a singleton controller that manages resource allocation and synchronization.

### The 4-Player System
To achieve gapless crossfading without stopping the beat, the engine orchestrates 4 simultaneous instances of `just_audio`:

1.  **`_drumPlayer` (The Anchor):** Plays the rhythmic foundation. Loops continuously.
2.  **`_neuroPlayer` (The Science):** Plays the selected frequency tone.
3.  **`_melodyPlayerA`:** The currently active melody.
4.  **`_melodyPlayerB`:** The buffer player. It pre-loads the *next* random loop and fades in while Player A fades out.

### The Algorithm
```dart
// Simplified Logic Flow
Timer.periodic(15_seconds, () {
  1. Select random loop from Asset Pool (excluding current).
  2. Pre-load into Inactive Player (e.g., Player B).
  3. Start Player B (Synced with Drums).
  4. Linear Volume Crossfade (A -> 0.0, B -> 1.0).
  5. Swap Active Player flags.
});
📂 Project Structure
code
Text
download
content_copy
expand_less
lib/
├── engine/
│   └── lofi_engine.dart    # Core logic, crossfading, and player management.
├── main.dart               # UI layer and controls.
assets/
├── audio/
    ├── drums/              # Rhythmic loops (80 BPM)
    ├── chords/             # Melodic loops (Key: C Min, 80 BPM)
    └── neuro/              # Isochronic tone loops (OGG)
🚀 Getting Started

Note: This project relies on precise audio timing. Run on a physical device for the best experience. Simulators often have audio latency issues.

Clone the repository

git clone https://github.com/YOUR_USERNAME/flutter-generative-lofi-engine.git

Install dependencies

flutter pub get

Run the App

flutter run


🛠 Tech Stack

Flutter & Dart

just_audio: For low-level audio handling and gapless playback.

Timer & Futures: For asynchronous synchronization of audio stems.

🔮 Future Roadmap

Integration with audio_service for background playback controls.

Visualizer based on real-time FFT (Audio Waveform).

"Station" system to switch vibes (e.g., Jazz, Synthwave).

Developed with ❤️ by SK
