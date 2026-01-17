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

    // 2. Setup Melody A (Normal Pitch)
    await _melodyPlayerA.setAsset(_melodyAssets[0]);
    await _melodyPlayerA.setLoopMode(LoopMode.one);
    await _melodyPlayerA.setVolume(1.0);

    // Set Pitch to 1.0 (Normal) to ensure consistent timing
    await _melodyPlayerA.setPitch(1.0);
    await _melodyPlayerB.setPitch(1.0);

    // 3. Setup Melody B
    await _melodyPlayerB.setLoopMode(LoopMode.one);
    await _melodyPlayerB.setVolume(0.0);
  }

  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;

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
    // Longer duration (24s) hides the loop better
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 24), (timer) {
      _performCrossfade();
    });
  }

  Future<void> _performCrossfade() async {
    print("Engine: Mixing new layer...");

    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    // 1. VARIATION TRICK: Pick a random pitch for the NEW melody
    // This creates "New Tracks" from the same file.
    // 1.0 = Normal, 0.94 = -1 Semitone, 1.05 = +1 Semitone
    // We only use subtle shifts so it doesn't sound like a chipmunk.
    final List<double> pitchOptions = [0.943, 1.0, 1.059];
    double newPitch = pitchOptions[_random.nextInt(pitchOptions.length)];

    // 2. Pick a new Melody Asset
    String nextAsset = _melodyAssets[_random.nextInt(_melodyAssets.length)];

    // Load asset and apply the new "Vibe" (Pitch)
    await playerIn.setAsset(nextAsset);
    await playerIn.setPitch(newPitch);

    if (!playerIn.playing) playerIn.play();

    // 3. EQUAL POWER CROSSFADE (The "Professional" Fade)
    // Instead of linear math, we use Cosine/Sine to keep volume powerful
    const steps = 40; // Smoother, more steps
    const stepDuration = Duration(milliseconds: 100); // 4 seconds total fade! Longer is better.

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);

      double fraction = i / steps;
      // The "Equal Power" Math formula:
      double volIn = sin(fraction * (pi / 2));
      double volOut = cos(fraction * (pi / 2));

      playerIn.setVolume(volIn);
      playerOut.setVolume(volOut);
    }

    _usingPlayerA = !_usingPlayerA;
  }

  void dispose() {
    _drumPlayer.dispose();
    _atmospherePlayer.dispose();
    _neuroPlayer.dispose();
    _melodyPlayerA.dispose();
    _melodyPlayerB.dispose();
    _crossfadeTimer?.cancel();
  }
}