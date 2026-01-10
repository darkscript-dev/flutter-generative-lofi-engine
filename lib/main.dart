import 'package:flutter/material.dart';
import 'engine/lofi_engine.dart';

void main() {
  runApp(const MaterialApp(home: LofiTestScreen()));
}

class LofiTestScreen extends StatefulWidget {
  const LofiTestScreen({super.key});

  @override
  State<LofiTestScreen> createState() => _LofiTestScreenState();
}

class _LofiTestScreenState extends State<LofiTestScreen> {
  final LofiEngine _engine = LofiEngine();
  double _neuroVolume = 0.2;

  @override
  void initState() {
    super.initState();
    _engine.init(); // Prepare the audio
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: const Text("Infinite Lofi Engine")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Display
            const Icon(Icons.headphones, size: 80, color: Colors.cyan),
            const SizedBox(height: 20),
            const Text(
              "Generative Audio Test",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _engine.play(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("PLAY"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => _engine.stop(),
                  icon: const Icon(Icons.stop),
                  label: const Text("STOP"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Neuro Slider
            const Text("Neuro/Brainwave Strength", style: TextStyle(color: Colors.white)),
            Slider(
              value: _neuroVolume,
              min: 0.0,
              max: 1.0,
              activeColor: Colors.cyan,
              onChanged: (val) {
                setState(() => _neuroVolume = val);
                _engine.setNeuroVolume(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}