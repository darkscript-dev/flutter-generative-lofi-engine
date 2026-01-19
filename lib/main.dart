import 'package:flutter/material.dart';
import 'engine/lofi_engine.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TestLabScreen(),
  ));
}

class TestLabScreen extends StatefulWidget {
  const TestLabScreen({super.key});

  @override
  State<TestLabScreen> createState() => _TestLabScreenState();
}

class _TestLabScreenState extends State<TestLabScreen> {
  // Instance of our Audio Engine
  final LofiEngine _engine = LofiEngine();

  // State variables
  bool _isReady = false;
  bool _isPlaying = false;

  // Slider Values
  double _neuroVol = 0.0;    // Starts silent
  double _atmosVol = 0.5;    // Starts at 50%
  double _masterPitch = 1.0; // Starts Normal (1.0)

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  // Initialize the engine and assets
  Future<void> _initEngine() async {
    await _engine.init();
    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  void dispose() {
    _engine.dispose(); // Cleanup players to prevent memory leaks
    super.dispose();
  }

  // Helper to name the Vibe based on Pitch
  String _getVibeName(double pitch) {
    if (pitch <= 0.9) return "☁️ VAPORWAVE (Slowed)";
    if (pitch >= 1.1) return "🔥 NIGHTCORE (Fast)";
    return "✨ NORMAL LOFI";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark Background
      appBar: AppBar(
        title: const Text("Infinite Lofi Engine"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _isReady
            ? _buildControls()
            : const CircularProgressIndicator(color: Colors.cyanAccent),
      ),
    );
  }

  Widget _buildControls() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Visual Status
          Icon(
              _isPlaying ? Icons.graphic_eq : Icons.music_off_outlined,
              color: _isPlaying ? Colors.cyanAccent : Colors.grey,
              size: 80
          ),
          const SizedBox(height: 10),
          Text(
            _isPlaying ? "GENERATING STREAM..." : "ENGINE IDLE",
            style: TextStyle(
                color: _isPlaying ? Colors.cyanAccent : Colors.grey,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold
            ),
          ),

          const SizedBox(height: 40),

          // 2. Play / Stop Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBigButton(
                  label: "PLAY",
                  icon: Icons.play_arrow,
                  color: Colors.greenAccent,
                  onTap: () {
                    _engine.play();
                    setState(() => _isPlaying = true);
                  }
              ),
              const SizedBox(width: 20),
              _buildBigButton(
                  label: "STOP",
                  icon: Icons.stop,
                  color: Colors.redAccent,
                  onTap: () {
                    _engine.stop();
                    setState(() => _isPlaying = false);
                  }
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          const SizedBox(height: 10),

          // 3. MASTER VIBE CONTROL (Pitch/Speed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3))
              ),
              child: Column(
                children: [
                  Text(
                      _getVibeName(_masterPitch),
                      style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      )
                  ),
                  Slider(
                    value: _masterPitch,
                    min: 0.75, // Deep
                    max: 1.25, // Fast
                    divisions: 10, // Snap points
                    activeColor: Colors.purpleAccent,
                    inactiveColor: Colors.purple.withOpacity(0.2),
                    onChanged: (val) {
                      setState(() => _masterPitch = val);
                      _engine.setMasterPitch(val);
                    },
                  ),
                  Text(
                      "Speed: ${(_masterPitch * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white38, fontSize: 12)
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. Mixing Sliders (Neuro & Atmosphere)
          _buildVolumeSlider(
              "🧠 Neuro Layer (10Hz Alpha)",
              _neuroVol,
                  (val) {
                setState(() => _neuroVol = val);
                _engine.setNeuroVolume(val);
              }
          ),

          _buildVolumeSlider(
              "🌧️ Atmosphere (Vinyl/Noise)",
              _atmosVol,
                  (val) {
                setState(() => _atmosVol = val);
                _engine.setAtmosphereVolume(val);
              }
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper Widget for Big Buttons
  Widget _buildBigButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
      ),
    );
  }

  // Helper Widget for Volume Sliders
  Widget _buildVolumeSlider(String label, double val, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          Slider(
            value: val,
            min: 0.0,
            max: 1.0,
            activeColor: Colors.cyanAccent,
            inactiveColor: Colors.grey[800],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}