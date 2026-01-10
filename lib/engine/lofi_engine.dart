import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';

/// A generative audio engine that layers drums, melody, and neuro-acoustics.
///
/// Logic:
/// 1. Drums play continuously (The Anchor).
/// 2. Two Melody players crossfade between loops to create infinite variety.
/// 3. Neuro player provides Isochronic tones for Brainwave Entrainment.
class LofiEngine {
  // We use multiple players to allow simultaneous layer mixing.
  final AudioPlayer _drumPlayer = AudioPlayer();
  final AudioPlayer _neuroPlayer = AudioPlayer();

  // Two players dedicated to crossfading melodies (A/B testing pattern).
  final AudioPlayer _melodyPlayerA = AudioPlayer();
  final AudioPlayer _melodyPlayerB = AudioPlayer();

  Timer? _crossfadeTimer;
  final Random _random = Random();
  bool _usingPlayerA = true; // State tracker for crossfading
  bool _isPlaying = false;

  // Configuration
  // In a real app, these would be passed via a Constructor Model.
  final List<String> _drumAssets = ['assets/audio/drums/beat_1.ogg'];
  final List<String> _melodyAssets = [
    'assets/audio/chords/piano_1.ogg',
    'assets/audio/chords/piano_2.ogg',
    'assets/audio/chords/guitar_1.ogg',
  ];
  final String _neuroAsset = 'assets/audio/neuro/alpha_10hz.ogg';

  /// Pre-loads all assets to memory to prevent playback latency.
  Future<void> init() async {
    // 1. Setup Anchor (Drums)
    await _drumPlayer.setAsset(_drumAssets[0]);
    await _drumPlayer.setLoopMode(LoopMode.one);

    // 2. Setup Brainwave Layer (Quiet background layer)
    await _neuroPlayer.setAsset(_neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.15); // Subtle default

    // 3. Setup Melody Layer A (Start active)
    await _melodyPlayerA.setAsset(_melodyAssets[0]);
    await _melodyPlayerA.setLoopMode(LoopMode.one);
    await _melodyPlayerA.setVolume(1.0);

    // 4. Setup Melody Layer B (Start silent/ready)
    await _melodyPlayerB.setLoopMode(LoopMode.one);
    await _melodyPlayerB.setVolume(0.0);
  }

  /// Triggers synchronized playback of all stems.
  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;

    // Future.wait ensures minimal drift between stems.
    await Future.wait([
      _drumPlayer.play(),
      _neuroPlayer.play(),
      _melodyPlayerA.play(),
      _melodyPlayerB.play(),
    ]);

    _startCrossfadeCycle();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _crossfadeTimer?.cancel();
    await Future.wait([
      _drumPlayer.stop(),
      _neuroPlayer.stop(),
      _melodyPlayerA.stop(),
      _melodyPlayerB.stop(),
    ]);
  }

  /// Controls the volume of the Isochronic Tone layer independently.
  void setNeuroVolume(double volume) {
    _neuroPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Initiates the automated DJ logic to swap tracks.
  void _startCrossfadeCycle() {
    // Every 15 seconds, we swap the melody loop.
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _performCrossfade();
    });
  }

  /// Swaps the active melody player with a linear volume fade.
  Future<void> _performCrossfade() async {
    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    // Select a new random loop that ISN'T the current one (if possible)
    final nextLoop = _melodyAssets[_random.nextInt(_melodyAssets.length)];
    await playerIn.setAsset(nextLoop);
    if (!playerIn.playing) playerIn.play();

    // Linear Crossfade Logic
    const steps = 20;
    const stepDuration = Duration(milliseconds: 100); // 2-second fade

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      double vol = i / steps;
      playerIn.setVolume(vol);       // Fade In
      playerOut.setVolume(1.0 - vol); // Fade Out
    }

    _usingPlayerA = !_usingPlayerA; // Toggle active player
  }

  void dispose() {
    _drumPlayer.dispose();
    _neuroPlayer.dispose();
    _melodyPlayerA.dispose();
    _melodyPlayerB.dispose();
    _crossfadeTimer?.cancel();
  }
}