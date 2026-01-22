import '../model/station.dart';

class StationData {
  // --- ASSET PATHS (Updated to match your screenshot) ---

  // Drums
  static const _drum80 = 'assets/audio/pool/drums/drum_80bpm_1.ogg';

  // Atmosphere
  static const _vinyl = 'assets/audio/pool/atmosphere/vinyl.ogg';
  static const _rain = 'assets/audio/pool/atmosphere/rain.ogg'; // <--- NOW USING RAIN

  // Neuro (Brainwaves)
  static const _alpha = 'assets/audio/neuro/alpha_10hz.ogg';

  // Melodies
  static const _melPiano = 'assets/audio/pool/melodies/piano_cmin.ogg';
  static const _melGuitar = 'assets/audio/pool/melodies/guitar_dmaj.ogg';
  static const _melAcoustic = 'assets/audio/pool/melodies/acoustic_cmaj.ogg';

  // --- STATION RECIPES ---

  static final List<Station> allStations = [
    // 1. CHILL HOP (Standard)
    Station(
      id: 'chill_hop',
      name: 'Chill Hop FM',
      description: 'Classic Focus Beats',
      drumAsset: _drum80,
      atmosphereAsset: _vinyl,
      neuroAsset: _alpha,
      melodyPool: [_melPiano, _melGuitar, _melAcoustic],
      pitch: 1.0,
    ),

    // 2. MIDNIGHT STUDY (Darker Vibe)
    Station(
      id: 'dark_mode',
      name: 'Midnight Study',
      description: 'Slowed for deep work',
      drumAsset: _drum80,
      atmosphereAsset: _rain, // <--- Using real Rain.ogg now
      neuroAsset: _alpha,
      melodyPool: [_melPiano, _melGuitar], // Excludes the bright acoustic
      pitch: 0.85, // SLOWED DOWN
      volumeDrums: 0.8,
    ),

    // 3. MORNING COFFEE (Brighter Vibe)
    Station(
      id: 'morning_vibes',
      name: 'Morning Coffee',
      description: 'Upbeat start',
      drumAsset: _drum80,
      atmosphereAsset: _vinyl,
      neuroAsset: _alpha,
      melodyPool: [_melAcoustic, _melGuitar], // Only Happy keys
      pitch: 1.05, // SPEEDED UP
    ),
  ];
}