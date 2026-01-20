import 'package:flutter/material.dart';
import 'engine/lofi_engine.dart';
import 'data/station_data.dart';
import 'model/station.dart';

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
  final LofiEngine _engine = LofiEngine();

  // State Variables
  bool _isReady = false;
  bool _isPlaying = false;
  String _selectedStationId = ''; // To highlight the active card

  // Slider Values
  double _neuroVol = 0.0;
  double _atmosVol = 0.5;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Initialize the players
    await _engine.init();

    // 2. Load the default station (Index 0 - Chill Hop)
    final defaultStation = StationData.allStations[0];
    await _loadStation(defaultStation);

    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  Future<void> _loadStation(Station station) async {
    await _engine.loadStation(station);
    setState(() {
      _selectedStationId = station.id;
    });
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _engine.stop();
    } else {
      await _engine.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
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
        title: const Text("Lofi Engine V2"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isReady
          ? _buildDashboard()
          : const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // 1. STATION SELECTOR (FM Tuner)
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("SELECT FREQUENCY",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, letterSpacing: 2)
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: StationData.allStations.length,
            itemBuilder: (context, index) {
              final station = StationData.allStations[index];
              final isSelected = station.id == _selectedStationId;

              return GestureDetector(
                onTap: () => _loadStation(station),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isSelected ? Colors.cyanAccent : Colors.transparent,
                        width: 2
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          isSelected ? Icons.radio : Icons.radio_outlined,
                          color: isSelected ? Colors.cyanAccent : Colors.grey,
                          size: 30
                      ),
                      const SizedBox(height: 12),
                      Text(
                        station.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        station.id == 'dark_mode' ? "Slowed" : (station.id == 'morning_vibes' ? "Fast" : "Normal"),
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Spacer(),

        // 2. BIG PLAY BUTTON
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: _isPlaying ? Colors.redAccent : Colors.greenAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: (_isPlaying ? Colors.red : Colors.green).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5
                  )
                ]
            ),
            child: Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              size: 40,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text(
          _isPlaying ? "ENGINE RUNNING" : "ENGINE STOPPED",
          style: TextStyle(color: Colors.grey[600], letterSpacing: 2, fontSize: 12),
        ),

        const Spacer(),

        // 3. MIXER CONTROLS
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("NEURO LAYER (10Hz Alpha)", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
              Slider(
                value: _neuroVol,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.grey[800],
                onChanged: (val) {
                  setState(() => _neuroVol = val);
                  _engine.setNeuroVolume(val);
                },
              ),
              const SizedBox(height: 10),
              const Text("ATMOSPHERE (Vinyl/Rain)", style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
              Slider(
                value: _atmosVol,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.purpleAccent,
                inactiveColor: Colors.grey[800],
                onChanged: (val) {
                  setState(() => _atmosVol = val);
                  _engine.setAtmosphereVolume(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}