import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MaterialApp(home: EngineTestScreen()));
}

class EngineTestScreen extends StatefulWidget {
  const EngineTestScreen({super.key});

  @override
  State<EngineTestScreen> createState() => _EngineTestScreenState();
}

class _EngineTestScreenState extends State<EngineTestScreen> {
  // --- THE PLAYERS ---
  final _drumPlayer = AudioPlayer();
  final _melodyPlayer = AudioPlayer();
  final _oneShotPlayer = AudioPlayer();

  // --- ENGINE STATE ---
  Timer? _melodySwapTimer;
  Timer? _oneShotTimer;
  String _currentStation = "Stopped";
  String _currentMelodyName = "None";

  // --- ASSETS (Matched to your specific files) ---
  // STATION 1: 80 BPM
  final List<String> drums80 = [
    'assets/audio/Cymatics - Eternity Percussion Loop 1 - 80 BPM.m4a',
    'assets/audio/Cymatics - Lofi Full Drum Loop 2 - 80 BPM.m4a',
  ];
  final List<String> melodies80 = [
    'assets/audio/Cymatics - Bordeaux - 80 BPM C Min.m4a',
    'assets/audio/Cymatics - Dreamscape - 80 BPM D# Min.m4a',
    'assets/audio/Cymatics - Dusk Acoustic Guitar Loop - 80 BPM C Maj.m4a',
  ];

  // STATION 2: 76 BPM
  final List<String> drums76 = [
    'assets/audio/Cymatics - Dreams Shaker Loop 2 - 76 BPM.m4a',
    'assets/audio/Cymatics - Dreams Shaker Loop 3 - 76 BPM.m4a',
  ];
  final List<String> melodies76 = [
    'assets/audio/Cymatics - Imagination - 76 BPM A# Min.m4a',
    'assets/audio/Cymatics - Misty Eyed - 76 BPM A# Min.m4a',
  ];

  final List<String> oneShots = [
    'assets/audio/Cymatics - Cartoon Bell One Shot - C.m4a',
    'assets/audio/Cymatics - Frozen Keys One Shot - C.m4a',
    'assets/audio/Cymatics - Kalimba Tape One Shot - C.m4a',
  ];

  @override
  void dispose() {
    _stopEngine();
    _drumPlayer.dispose();
    _melodyPlayer.dispose();
    _oneShotPlayer.dispose();
    super.dispose();
  }

  Future<void> _stopEngine() async {
    _melodySwapTimer?.cancel();
    _oneShotTimer?.cancel();
    await _drumPlayer.stop();
    await _melodyPlayer.stop();
    await _oneShotPlayer.stop();
    setState(() {
      _currentStation = "Stopped";
      _currentMelodyName = "None";
    });
  }

  Future<void> _startStation(String bpm) async {
    await _stopEngine(); // Reset first

    List<String> selectedDrums = [];
    List<String> selectedMelodies = [];

    if (bpm == '80') {
      selectedDrums = drums80;
      selectedMelodies = melodies80;
      setState(() => _currentStation = "Deep Work (80 BPM)");
    } else {
      selectedDrums = drums76;
      selectedMelodies = melodies76;
      setState(() => _currentStation = "Sunset Chill (76 BPM)");
    }

    // 1. Pick initial Assets
    final random = Random();
    String drum = selectedDrums[random.nextInt(selectedDrums.length)];
    String melody = selectedMelodies[random.nextInt(selectedMelodies.length)];

    setState(() => _currentMelodyName = melody.split('/').last);

    // 2. Load Players
    await _drumPlayer.setAsset(drum);
    await _melodyPlayer.setAsset(melody);

    // 3. Set Looping
    await _drumPlayer.setLoopMode(LoopMode.all);
    await _melodyPlayer.setLoopMode(LoopMode.all);

    // 4. Set Volume Balance (TUNE THIS DURING TESTING)
    await _drumPlayer.setVolume(1.0);
    await _melodyPlayer.setVolume(0.75); // Melodies usually need to be slightly quieter
    await _oneShotPlayer.setVolume(0.5); // Accents should be background

    // 5. Play Synced
    _drumPlayer.play();
    _melodyPlayer.play();

    // 6. Start The "Infinite" Generators
    _startMelodySwapper(selectedMelodies);
    _startOneShotGenerator();
  }

  void _startMelodySwapper(List<String> pool) {
    // Swap melody every 10 seconds (Short for testing purposes)
    // In real app, make this 45-60 seconds
    _melodySwapTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final random = Random();
      String nextMelody = pool[random.nextInt(pool.length)];

      print("Swapping Melody to: $nextMelody");
      setState(() => _currentMelodyName = nextMelody.split('/').last);

      // Instant swap (Crossfading requires more complex code, simplistic for test)
      await _melodyPlayer.setAsset(nextMelody);
      _melodyPlayer.play();
    });
  }

  void _startOneShotGenerator() {
    // Random sound every 3-6 seconds (Fast for testing)
    final random = Random();
    int nextDelay = 3 + random.nextInt(3);

    _oneShotTimer = Timer(Duration(seconds: nextDelay), () async {
      if (!_drumPlayer.playing) return;

      String shot = oneShots[random.nextInt(oneShots.length)];
      print("Playing One Shot: $shot");

      await _oneShotPlayer.setAsset(shot);
      _oneShotPlayer.play();

      _startOneShotGenerator(); // Recursive loop
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("LOFI ENGINE TEST", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            Text("Status: $_currentStation", style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 18)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Current Melody:\n$_currentMelodyName", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),

            const SizedBox(height: 40),

            // CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton("Play 80 BPM\n(Deep Work)", () => _startStation('80'), Colors.green),
                _buildButton("Play 76 BPM\n(Sunset)", () => _startStation('76'), Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            _buildButton("STOP ENGINE", _stopEngine, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.all(20)),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}