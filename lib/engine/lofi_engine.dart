import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import '../model/station.dart';

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

  Station? _currentStation;
  double _currentPitch = 1.0;

  Future<void> init() async {
    print("Engine: Initializing...");
    await _neuroPlayer.setLoopMode(LoopMode.one);
  }

  Future<void> loadStation(Station station) async {
    _currentStation = station;
    _currentPitch = station.pitch;

    bool wasPlaying = _isPlaying;
    if (wasPlaying) await stop();

    print("Engine: Loading Channel ${station.name}...");

    // 1. Drums
    await _drumPlayer.setAudioSource(_createGaplessLoop(station.drumAsset));
    await _drumPlayer.setLoopMode(LoopMode.all);
    await _drumPlayer.setVolume(station.volumeDrums);

    // 2. Atmosphere
    await _atmospherePlayer.setAudioSource(_createGaplessLoop(station.atmosphereAsset));
    await _atmospherePlayer.setLoopMode(LoopMode.all);
    await _atmospherePlayer.setVolume(0.5);

    // 3. Neuro
    await _neuroPlayer.setAsset(station.neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.0);

    // 4. Melody A
    String firstMelody = station.melodyPool[0];
    await _melodyPlayerA.setAudioSource(_createGaplessLoop(firstMelody));
    await _melodyPlayerA.setLoopMode(LoopMode.all);
    await _melodyPlayerA.setVolume(station.volumeMelody);

    // 5. Melody B (Silent)
    await _melodyPlayerB.setLoopMode(LoopMode.all);
    await _melodyPlayerB.setVolume(0.0);

    await _applyMasterPitch(_currentPitch);

    if (wasPlaying) await play();
  }

  Future<void> play() async {
    if (_currentStation == null) return;
    _isPlaying = true;

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

  Future<void> setMasterPitch(double pitch) async {
    _currentPitch = pitch.clamp(0.5, 1.5);
    await _applyMasterPitch(_currentPitch);
  }

  Future<void> _applyMasterPitch(double pitch) async {
    await Future.wait([
      _drumPlayer.setPitch(pitch),
      _atmospherePlayer.setPitch(pitch),
      _melodyPlayerA.setPitch(pitch),
      _melodyPlayerB.setPitch(pitch),
    ]);
  }

  void setNeuroVolume(double val) => _neuroPlayer.setVolume(val.clamp(0.0, 1.0));
  void setAtmosphereVolume(double val) => _atmospherePlayer.setVolume(val.clamp(0.0, 1.0));

  void _startCrossfadeTimer() {
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 24), (timer) {
      _performCrossfade();
    });
  }

  Future<void> _performCrossfade() async {
    if (_currentStation == null) return;

    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;

    List<String> pool = _currentStation!.melodyPool;
    String nextAsset = pool[_random.nextInt(pool.length)];

    await playerIn.setAudioSource(_createGaplessLoop(nextAsset));
    await playerIn.setPitch(_currentPitch);

    // SYNC LOGIC (Modulo Fix for infinite loop)
    final loopDuration = const Duration(seconds: 24).inMilliseconds;
    final currentPos = _drumPlayer.position.inMilliseconds;
    final relativePos = currentPos % loopDuration;

    await playerIn.seek(Duration(milliseconds: relativePos));

    if (!playerIn.playing) playerIn.play();

    const steps = 40;
    const stepDuration = Duration(milliseconds: 100);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      if (!_isPlaying) return;

      double fraction = i / steps;
      double volIn = sin(fraction * (pi / 2));
      double volOut = cos(fraction * (pi / 2));

      playerIn.setVolume(volIn * _currentStation!.volumeMelody);
      playerOut.setVolume(volOut * _currentStation!.volumeMelody);
    }

    _usingPlayerA = !_usingPlayerA;
  }

  ConcatenatingAudioSource _createGaplessLoop(String assetPath) {
    List<AudioSource> children = [];
    for (int i = 0; i < 50; i++) {
      children.add(AudioSource.asset(assetPath));
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