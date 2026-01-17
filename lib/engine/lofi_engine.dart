import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';

class LofiEngine {
  // --- The Players (5 Layer System) ---
  final AudioPlayer _drumPlayer = AudioPlayer();       // Layer 1: The Beat
  final AudioPlayer _atmospherePlayer = AudioPlayer(); // Layer 2: Vinyl/Rain
  final AudioPlayer _neuroPlayer = AudioPlayer();      // Layer 3: Science

  // Layers 4 & 5: The "Infinite" Melody (Crossfading)
  final AudioPlayer _melodyPlayerA = AudioPlayer();
  final AudioPlayer _melodyPlayerB = AudioPlayer();

  // --- Internal Logic ---
  Timer? _crossfadeTimer;
  final Random _random = Random();
  bool _usingPlayerA = true; // Keeps track of which player is active
  bool _isPlaying = false;

  // --- Configuration (The "Chill" Station Assets) ---
  final String _drumAsset = 'assets/audio/stations/chill_80bpm/drums/drums.ogg';
  final String _atmosAsset = 'assets/audio/stations/chill_80bpm/atmosphere/noise.ogg';
  final String _neuroAsset = 'assets/audio/neuro/iso_pulse_10hz.ogg';

  final List<String> _melodyAssets = [
    'assets/audio/stations/chill_80bpm/melodies/melody_1.ogg',
    'assets/audio/stations/chill_80bpm/melodies/melody_2.ogg',
    'assets/audio/stations/chill_80bpm/melodies/melody_3.ogg',
  ];

  /// Initialize all players and load assets into memory.
  Future<void> init() async {
    print("Engine: Initializing...");

    // 1. Setup Steady Loops
    await _drumPlayer.setAsset(_drumAsset);
    await _drumPlayer.setLoopMode(LoopMode.one);

    await _atmospherePlayer.setAsset(_atmosAsset);
    await _atmospherePlayer.setLoopMode(LoopMode.one);
    await _atmospherePlayer.setVolume(0.5); // Noise shouldn't be too loud

    await _neuroPlayer.setAsset(_neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.0); // Start silent, let user fade it in

    // 2. Setup Melody Players
    // We start Player A with the first melody
    await _melodyPlayerA.setAsset(_melodyAssets[0]);
    await _melodyPlayerA.setLoopMode(LoopMode.one);
    await _melodyPlayerA.setVolume(1.0);

    // Player B is ready but silent
    await _melodyPlayerB.setLoopMode(LoopMode.one);
    await _melodyPlayerB.setVolume(0.0);

    print("Engine: Ready.");
  }

  /// Start the Engine
  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;

    // Start all 5 players at the exact same time
    await Future.wait([
      _drumPlayer.play(),
      _atmospherePlayer.play(),
      _neuroPlayer.play(),
      _melodyPlayerA.play(),
      _melodyPlayerB.play(),
    ]);

    // Start the algorithmic crossfading
    _startCrossfadeTimer();
  }

  /// Stop the Engine
  Future<void> stop() async {
    _isPlaying = false;
    _crossfadeTimer?.cancel();
    await Future.wait([
      _drumPlayer.stop(),
      _atmospherePlayer.stop(),
      _neuroPlayer.stop(),
      _melodyPlayerA.stop(),
      _melodyPlayerB.stop(),
    ]);
  }

  // --- Volume Controls for the UI ---

  void setNeuroVolume(double val) {
    // Clamp ensures we never crash with invalid volume numbers
    _neuroPlayer.setVolume(val.clamp(0.0, 1.0));
  }

  void setAtmosphereVolume(double val) {
    _atmospherePlayer.setVolume(val.clamp(0.0, 1.0));
  }

  // --- The Generative Logic ---

  void _startCrossfadeTimer() {
    // Real Lofi songs change every 8 or 16 bars.
    // At 80 BPM, 1 bar = 3 seconds. 8 bars = 24 seconds.
    // For testing, let's do 12 seconds so you can hear it work faster.
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      _performCrossfade();
    });
  }

  Future<void> _performCrossfade() async {
    print("Engine: Swapping Melody...");

    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    // Pick a random melody, but try to avoid the one currently playing
    String nextAsset;
    do {
      nextAsset = _melodyAssets[_random.nextInt(_melodyAssets.length)];
    } while (_melodyAssets.length > 1 && nextAsset == _getCurrentAsset(playerOut));

    // Load the new track into the silent player
    await playerIn.setAsset(nextAsset);
    // Ensure it's playing (it might have paused if asset changed)
    if (!playerIn.playing) playerIn.play();

    // SMOOTH CROSSFADE ANIMATION
    // We change volume 20 times over 2 seconds
    const steps = 20;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      double vol = i / steps;

      playerIn.setVolume(vol);        // 0.0 -> 1.0
      playerOut.setVolume(1.0 - vol); // 1.0 -> 0.0
    }

    // Flip the flag
    _usingPlayerA = !_usingPlayerA;
  }

  // Helper to get current asset path if possible (just_audio doesn't expose this easily publically,
  // so we just rely on logic, but this is a placeholder if you needed it)
  String? _getCurrentAsset(AudioPlayer p) => null;

  void dispose() {
    _drumPlayer.dispose();
    _atmospherePlayer.dispose();
    _neuroPlayer.dispose();
    _melodyPlayerA.dispose();
    _melodyPlayerB.dispose();
    _crossfadeTimer?.cancel();
  }
}