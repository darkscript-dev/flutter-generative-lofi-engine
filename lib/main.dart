import 'package:flutter/material.dart';
import 'engine/lofi_engine.dart';

void main() {
  runApp(const MaterialApp(home: TestLabScreen()));
}

class TestLabScreen extends StatefulWidget {
  const TestLabScreen({super.key});

  @override
  State<TestLabScreen> createState() => _TestLabScreenState();
}

class _TestLabScreenState extends State<TestLabScreen> {
  final LofiEngine _engine = LofiEngine();
  bool _isReady = false;

  // Slider Values
  double _neuroVol = 0.0;
  double _atmosVol = 0.5;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    await _engine.init();
    setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Lofi Engine V1"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isReady
            ? _buildControls()
            : const CircularProgressIndicator(color: Colors.cyan),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status Light
        const Icon(Icons.graphic_eq, color: Colors.cyan, size: 60),
        const SizedBox(height: 40),

        // Play / Stop Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("START ENGINE"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
              ),
              onPressed: () => _engine.play(),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text("STOP"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white
              ),
              onPressed: () => _engine.stop(),
            ),
          ],
        ),

        const SizedBox(height: 50),

        // Sliders
        _buildSlider(
            "Neuro Layer (10Hz Alpha)",
            _neuroVol,
                (val) {
              setState(() => _neuroVol = val);
              _engine.setNeuroVolume(val);
            }
        ),

        _buildSlider(
            "Atmosphere (Vinyl)",
            _atmosVol,
                (val) {
              setState(() => _atmosVol = val);
              _engine.setAtmosphereVolume(val);
            }
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double val, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Slider(
            value: val,
            min: 0.0,
            max: 1.0,
            activeColor: Colors.cyan,
            inactiveColor: Colors.grey[800],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}