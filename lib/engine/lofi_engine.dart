import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import '../model/station.dart';

class LofiEngine {
  // --- The Players (5 Layer System) ---
  final AudioPlayer _drumPlayer = AudioPlayer();       // Layer 1: The Anchor
  final AudioPlayer _atmospherePlayer = AudioPlayer(); // Layer 2: Texture
  final AudioPlayer _neuroPlayer = AudioPlayer();      // Layer 3: Science (Brainwaves)

  // Layers 4 & 5: The "Infinite" Melody (Crossfading)
  final AudioPlayer _melodyPlayerA = AudioPlayer();
  final AudioPlayer _melodyPlayerB = AudioPlayer();

  // --- Internal Logic ---
  Timer? _crossfadeTimer;
  final Random _random = Random();
  bool _usingPlayerA = true; // Keeps track of which melody player is active
  bool _isPlaying = false;

  // State
  Station? _currentStation;
  double _currentPitch = 1.0;

  /// Initialize players (Basic setup)
  Future<void> init() async {
    print("Engine: Initializing Players...");
    // We don't load assets here anymore. We wait for loadStation().
    // Just ensure loop modes are ready for the non-playlist players if needed.
    await _neuroPlayer.setLoopMode(LoopMode.one);
  }

  /// LOAD A STATION (The "Change Channel" Logic)
  /// This configures the engine based on the 'Station' recipe.
  Future<void> loadStation(Station station) async {
    _currentStation = station;
    _currentPitch = station.pitch; // Reset pitch to station default

    bool wasPlaying = _isPlaying;
    if (wasPlaying) await stop(); // Stop current if playing to reload safely

    print("Engine: Loading Channel ${station.name}...");

    // 1. Setup Drums (Gapless Playlist)
    await _drumPlayer.setAudioSource(_createGaplessLoop(station.drumAsset));
    await _drumPlayer.setLoopMode(LoopMode.all);
    await _drumPlayer.setVolume(station.volumeDrums);

    // 2. Setup Atmosphere (Gapless Playlist)
    await _atmospherePlayer.setAudioSource(_createGaplessLoop(station.atmosphereAsset));
    await _atmospherePlayer.setLoopMode(LoopMode.all);
    await _atmospherePlayer.setVolume(0.5);

    // 3. Setup Neuro (Simple Loop)
    // Brainwaves are simple tones, LoopMode.one is usually fine/safe here.
    await _neuroPlayer.setAsset(station.neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.0); // Default off, controlled by UI slider

    // 4. Setup Melody Pool
    // Pick the first song from the station's specific pool
    String firstMelody = station.melodyPool[0];
    await _melodyPlayerA.setAudioSource(_createGaplessLoop(firstMelody));
    await _melodyPlayerA.setLoopMode(LoopMode.all);
    await _melodyPlayerA.setVolume(station.volumeMelody);

    // 5. Setup Player B (Silent & Ready)
    // We don't load a source yet, just prep it.
    await _melodyPlayerB.setLoopMode(LoopMode.all);
    await _melodyPlayerB.setVolume(0.0);

    // 6. Apply the Station's Vibe (Speed/Pitch)
    await _applyMasterPitch(_currentPitch);

    if (wasPlaying) await play(); // Resume if we were playing
  }

  /// Start the Engine (Synchronized Start)
  Future<void> play() async {
    if (_currentStation == null) return;
    _isPlaying = true;

    // HARD SYNC: Force all players to start exactly at 0:00
    // This aligns the beats perfectly.
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

  /// Change the Speed/Pitch of the entire station dynamically
  Future<void> setMasterPitch(double pitch) async {
    _currentPitch = pitch.clamp(0.5, 1.5);
    await _applyMasterPitch(_currentPitch);
  }

  Future<void> _applyMasterPitch(double pitch) async {
    // We apply pitch to everything EXCEPT Neuro (Science needs precise Hz)
    await Future.wait([
      _drumPlayer.setPitch(pitch),
      _atmospherePlayer.setPitch(pitch),
      _melodyPlayerA.setPitch(pitch),
      _melodyPlayerB.setPitch(pitch),
    ]);
  }

  // --- Volume Setters ---
  void setNeuroVolume(double val) => _neuroPlayer.setVolume(val.clamp(0.0, 1.0));
  void setAtmosphereVolume(double val) => _atmospherePlayer.setVolume(val.clamp(0.0, 1.0));

  // --- The Infinite Logic ---

  void _startCrossfadeTimer() {
    // 24 seconds = 8 bars at 80bpm.
    // This is a musical length to change the chord progression.
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 24), (timer) {
      _performCrossfade();
    });
  }

  Future<void> _performCrossfade() async {
    if (_currentStation == null) return;
    print("Engine: Mixing new layer...");

    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    // 1. Pick a RANDOM melody from the current station's pool
    List<String> pool = _currentStation!.melodyPool;
    String nextAsset = pool[_random.nextInt(pool.length)];

    // 2. Prepare the Player
    // Use the Playlist Trick for gapless looping
    await playerIn.setAudioSource(_createGaplessLoop(nextAsset));

    // Important: Ensure the new player has the current Vibe (Pitch)
    await playerIn.setPitch(_currentPitch);

    // 3. THE SYNC FIX (Crucial)
    // We look at exactly where the drums are, and snap the new melody
    // to that exact timestamp. This prevents "Drift" over time.
    final currentDrumPosition = _drumPlayer.position;
    await playerIn.seek(currentDrumPosition);

    if (!playerIn.playing) playerIn.play();

    // 4. Equal Power Crossfade (Sine/Cosine Math)
    // This maintains constant energy levels during the mix.
    const steps = 40;
    const stepDuration = Duration(milliseconds: 100); // 4 second smooth fade

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);

      // Stop if user stopped the engine mid-fade
      if (!_isPlaying) return;

      double fraction = i / steps;
      double volIn = sin(fraction * (pi / 2));
      double volOut = cos(fraction * (pi / 2));

      // Apply volume (multiplied by the Station's preferred mixing level)
      playerIn.setVolume(volIn * _currentStation!.volumeMelody);
      playerOut.setVolume(volOut * _currentStation!.volumeMelody);
    }

    _usingPlayerA = !_usingPlayerA; // Swap active player
  }

  /// Helper: Creates a list of 50 copies of the same file.
  /// This forces Android/ExoPlayer to pre-buffer the loop, removing the gap.
  ConcatenatingAudioSource _createGaplessLoop(String assetPath) {
    List<AudioSource> children = [];
    // 50 copies * 24 seconds = ~20 minutes of gapless audio before a tiny seek.
    // Since we crossfade every 24s, the user never hears the end of this list.
    for (int i = 0; i < 50; i++) {
      children.add(AudioSource.uri(Uri.parse('asset:///$assetPath')));
    }
    return ConcatenatingAudioSource(children: children);
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