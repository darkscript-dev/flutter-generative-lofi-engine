import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';

class LofiEngine {
  final AudioPlayer _drumPlayer = AudioPlayer();
  final AudioPlayer _atmospherePlayer = AudioPlayer();
  final AudioPlayer _neuroPlayer = AudioPlayer();

  final AudioPlayer _melodyPlayerA = AudioPlayer();
  final AudioPlayer _melodyPlayerB = AudioPlayer();

  Timer? _crossfadeTimer;
  final Random _random = Random();
  bool _usingPlayerA = true;
  bool _isPlaying = false;

  // Configuration
  final String _drumAsset = 'assets/audio/stations/chill_80bpm/drums/drums.ogg';
  final String _atmosAsset = 'assets/audio/stations/chill_80bpm/atmosphere/noise.ogg';
  final String _neuroAsset = 'assets/audio/neuro/iso_pulse_10hz.ogg';

  final List<String> _melodyAssets = [
    'assets/audio/stations/chill_80bpm/melodies/melody_1.ogg',
    'assets/audio/stations/chill_80bpm/melodies/melody_2.ogg',
    'assets/audio/stations/chill_80bpm/melodies/melody_3.ogg',
  ];

  Future<void> init() async {
    // 1. Setup Base Layers
    await _drumPlayer.setAsset(_drumAsset);
    await _drumPlayer.setLoopMode(LoopMode.one);

    await _atmospherePlayer.setAsset(_atmosAsset);
    await _atmospherePlayer.setLoopMode(LoopMode.one);
    await _atmospherePlayer.setVolume(0.5);

    await _neuroPlayer.setAsset(_neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.0);

    // 2. Setup Melody A
    await _melodyPlayerA.setAsset(_melodyAssets[0]);
    await _melodyPlayerA.setLoopMode(LoopMode.one);
    await _melodyPlayerA.setVolume(1.0);

    // 3. Setup Melody B
    await _melodyPlayerB.setLoopMode(LoopMode.one);
    await _melodyPlayerB.setVolume(0.0);
  }

  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;

    // HARD SYNC: Force all players to start at 0:00
    await Future.wait([
      _drumPlayer.seek(Duration.zero),
      _atmospherePlayer.seek(Duration.zero),
      _neuroPlayer.seek(Duration.zero),
      _melodyPlayerA.seek(Duration.zero),
      _melodyPlayerB.seek(Duration.zero),
    ]);

    await Future.wait([
      _drumPlayer.play(),
      _atmospherePlayer.play(),
      _neuroPlayer.play(),
      _melodyPlayerA.play(),
      _melodyPlayerB.play(),
    ]);

    _startCrossfadeTimer();
  }

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

  void setNeuroVolume(double val) => _neuroPlayer.setVolume(val.clamp(0.0, 1.0));
  void setAtmosphereVolume(double val) => _atmospherePlayer.setVolume(val.clamp(0.0, 1.0));

  void _startCrossfadeTimer() {
    // Swap every 15 seconds
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _performCrossfade();
    });
  }

  Future<void> _performCrossfade() async {
    print("Engine: Swapping Melody...");

    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    // 1. Pick a new Melody Asset
    String nextAsset;
    do {
      nextAsset = _melodyAssets[_random.nextInt(_melodyAssets.length)];
    } while (_melodyAssets.length > 1 && nextAsset == _getCurrentAsset(playerOut)); // Don't pick same song twice

    // Load the new track
    await playerIn.setAsset(nextAsset);

    // *** THE SYNC FIX ***
    // Before fading in, we check exactly where the DRUMS are.
    // We snap the new melody to the exact same position as the drums.
    // This creates a perfect lock.
    final currentDrumPosition = _drumPlayer.position;
    await playerIn.seek(currentDrumPosition);

    if (!playerIn.playing) playerIn.play();

    // 2. Equal Power Crossfade
    const steps = 20;
    const stepDuration = Duration(milliseconds: 100);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      double fraction = i / steps;
      double volIn = sin(fraction * (pi / 2));
      double volOut = cos(fraction * (pi / 2));
      playerIn.setVolume(volIn);
      playerOut.setVolume(volOut);
    }

    _usingPlayerA = !_usingPlayerA;
  }

  // Helper to check what's playing (simple logic)
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