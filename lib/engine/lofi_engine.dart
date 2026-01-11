import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';


class LofiEngine {

  final AudioPlayer _drumPlayer = AudioPlayer();
  final AudioPlayer _neuroPlayer = AudioPlayer();


  final AudioPlayer _melodyPlayerA = AudioPlayer();
  final AudioPlayer _melodyPlayerB = AudioPlayer();

  Timer? _crossfadeTimer;
  final Random _random = Random();
  bool _usingPlayerA = true;
  bool _isPlaying = false;


  final List<String> _drumAssets = ['assets/audio/drums/beat_1.ogg'];
  final List<String> _melodyAssets = [
    'assets/audio/chords/piano_1.ogg',
    'assets/audio/chords/piano_2.ogg',
    'assets/audio/chords/guitar_1.ogg',
  ];
  final String _neuroAsset = 'assets/audio/neuro/alpha_10hz.ogg';

  Future<void> init() async {
    await _drumPlayer.setAsset(_drumAssets[0]);
    await _drumPlayer.setLoopMode(LoopMode.one);


    await _neuroPlayer.setAsset(_neuroAsset);
    await _neuroPlayer.setLoopMode(LoopMode.one);
    await _neuroPlayer.setVolume(0.15);

    await _melodyPlayerA.setAsset(_melodyAssets[0]);
    await _melodyPlayerA.setLoopMode(LoopMode.one);
    await _melodyPlayerA.setVolume(1.0);


    await _melodyPlayerB.setLoopMode(LoopMode.one);
    await _melodyPlayerB.setVolume(0.0);
  }


  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;

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


  void setNeuroVolume(double volume) {
    _neuroPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  void _startCrossfadeCycle() {
    _crossfadeTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _performCrossfade();
    });
  }


  Future<void> _performCrossfade() async {
    final playerIn = _usingPlayerA ? _melodyPlayerB : _melodyPlayerA;
    final playerOut = _usingPlayerA ? _melodyPlayerA : _melodyPlayerB;


    final nextLoop = _melodyAssets[_random.nextInt(_melodyAssets.length)];
    await playerIn.setAsset(nextLoop);
    if (!playerIn.playing) playerIn.play();

    const steps = 20;
    const stepDuration = Duration(milliseconds: 100);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      double vol = i / steps;
      playerIn.setVolume(vol);
      playerOut.setVolume(1.0 - vol);
    }

    _usingPlayerA = !_usingPlayerA;
  }

  void dispose() {
    _drumPlayer.dispose();
    _neuroPlayer.dispose();
    _melodyPlayerA.dispose();
    _melodyPlayerB.dispose();
    _crossfadeTimer?.cancel();
  }
}