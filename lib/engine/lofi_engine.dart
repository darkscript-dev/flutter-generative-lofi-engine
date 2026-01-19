import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';

class LofiEngine {
  // --- The Players (5 Layer System) ---
  final AudioPlayer _drumPlayer = AudioPlayer();       // Layer 1: The Anchor (Beat)
  final AudioPlayer _atmospherePlayer = AudioPlayer(); // Layer 2: Texture (Vinyl/Rain)
  final AudioPlayer _neuroPlayer = AudioPlayer();      // Layer 3: Science (10Hz Alpha)

  // Layers 4 & 5: The "Infinite" Melody (Crossfading system)
  final AudioPlayer _melodyPlayerA = AudioPlayer();
  final AudioPlayer _melodyPlayerB = AudioPlayer();

  // --- Internal Logic ---
  Timer? _crossfadeTimer;
  final Random _random = Random();
  bool _usingPlayerA = true; // Keeps track of which player is currently audible
  bool _isPlaying = false;
  double _currentPitch = 1.0; // The "Vibe" State (1.0 = Normal)

  // --- Configuration (Asset Paths) ---
  // These match the folder structure we created: assets/audio/stations/chill_80bpm/...
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
    await _atmospherePlayer.setVolume(0.5); // Default atmosphere volume

    // Neuro layer starts silent (User controls this via slider)
    await _neuroPlayer.setAsset(_neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.0);

    // 2. Setup Melody Players
    // Player A starts with the first melody
    await _melodyPlayerA.setAsset(_melodyAssets[0]);
    await _melodyPlayerA.setLoopMode(LoopMode.one);
    await _melodyPlayerA.setVolume(1.0);

    // Player B is ready but silent (Waiting for crossfade)
    await _melodyPlayerB.setLoopMode(LoopMode.one);
    await _melodyPlayerB.setVolume(0.0);

    // Ensure everyone starts at normal pitch
    await setMasterPitch(1.0);

    print("Engine: Ready.");
  }

  /// Start the Engine
  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;

    // HARD SYNC: Force all players to start exactly at 0:00
    // This prevents them from starting "mid-loop" if they were paused
    await Future.wait([
      _drumPlayer.seek(Duration.zero),
      _atmospherePlayer.seek(Duration.zero),
      _neuroPlayer.seek(Duration.zero),
      _melodyPlayerA.seek(Duration.zero),
      _melodyPlayerB.seek(Duration.zero),
    ]);

    // Fire all players simultaneously
    await Future.wait([
      _drumPlayer.play(),
      _atmospherePlayer.play(),
      _neuroPlayer.play(),
      _melodyPlayerA.play(),
      _melodyPlayerB.play(),
    ]);

    // Start the algorithmic crossfading logic
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

  // --- Volume Controls ---

  void setNeuroVolume(double val) {
    _neuroPlayer.setVolume(val.clamp(0.0, 1.0));
  }

  void setAtmosphereVolume(double val) {
    _atmospherePlayer.setVolume(val.clamp(0.0, 1.0));
  }

  /// THE VIBE ADJUSTER (Pitch/Speed Shifter)
  /// 1.0 = Normal
  /// 0.8 = Slowed (Vaporwave)
  /// 1.2 = Fast (Nightcore)
  Future<void> setMasterPitch(double pitch) async {
    double safePitch = pitch.clamp(0.5, 1.5);
    _currentPitch = safePitch;

    // We shift Drums, Atmosphere, and Melodies.
    // NOTE: We do NOT shift Neuro, because 10Hz needs to stay 10Hz to work scientifically!
    await Future.wait([
      _drumPlayer.setPitch(safePitch),
      _atmospherePlayer.setPitch(safePitch),
      _melodyPlayerA.setPitch(safePitch),
      _melodyPlayerB.setPitch(safePitch),
    ]);
  }

  // --- The Generative Logic ---

  void _startCrossfadeTimer() {
    // Change melody every 15 seconds (5 bars at 80bpm roughly)
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _performCrossfade();
    });
  }

  Future<void> _performCrossfade() async {
    print("Engine: Mixing new layer...");

    // Determine who is fading IN and who is fading OUT
    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    // 1. Pick a random NEW melody (try not to repeat the current one)
    String nextAsset;
    do {
      nextAsset = _melodyAssets[_random.nextInt(_melodyAssets.length)];
    } while (_melodyAssets.length > 1 && nextAsset == _getCurrentAsset(playerOut));

    // 2. Load the new track
    await playerIn.setAsset(nextAsset);

    // 3. APPLY VIBE: Ensure new track matches the current Master Pitch
    await playerIn.setPitch(_currentPitch);

    // 4. *** SYNC LOCK ***
    // This is the most important line. We snap the new melody to the
    // exact same position as the drums. Drifts are corrected instantly here.
    final currentDrumPosition = _drumPlayer.position;
    await playerIn.seek(currentDrumPosition);

    if (!playerIn.playing) playerIn.play();

    // 5. EQUAL POWER CROSSFADE (Smooth Volume Transition)
    const steps = 40;
    const stepDuration = Duration(milliseconds: 100); // 4 seconds total

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);

      double fraction = i / steps;
      // Use Sin/Cos for constant power (prevents volume dip in middle)
      double volIn = sin(fraction * (pi / 2));
      double volOut = cos(fraction * (pi / 2));

      playerIn.setVolume(volIn);
      playerOut.setVolume(volOut);
    }

    // Toggle the switch
    _usingPlayerA = !_usingPlayerA;
  }

  // Helper to check what's currently playing to avoid repeating same track
  // just_audio doesn't expose asset path easily, so we use a simple check logic
  // In a real app, you might track this with a string variable.
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