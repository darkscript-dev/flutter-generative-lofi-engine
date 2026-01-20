import '../model/station.dart';

class StationData {
  // --- ASSET PATHS (Matched exactly to your screenshot) ---

  // Drums
  static const _drum80 = 'assets/audio/pool/drums/drum_80bpm_1.ogg';

  // Atmosphere
  static const _vinyl = 'assets/audio/pool/atmosphere/vinyl.ogg';
  // Note: You don't have 'rain.ogg' in your screenshot, so we will use vinyl for both
  // to prevent a crash. (You can add rain.ogg later!)
  static const _rainFallback = 'assets/audio/pool/atmosphere/vinyl.ogg';

  // Neuro (Brainwaves)
  // FIXED: Your file is named 'alpha_10hz.ogg', not 'iso_pulse_10hz.ogg'
  static const _alpha = 'assets/audio/neuro/alpha_10hz.ogg';

  // Melodies
  static const _melPiano = 'assets/audio/pool/melodies/piano_cmin.ogg';
  static const _melGuitar = 'assets/audio/pool/melodies/guitar_dmaj.ogg';
  static const _melAcoustic = 'assets/audio/pool/melodies/acoustic_cmaj.ogg';

  // --- STATION RECIPES ---

  static final List<Station> allStations = [
    // 1. CHILL HOP (The Standard)
    Station(
      id: 'chill_hop',
      name: 'Chill Hop FM',
      description: 'Classic Focus Beats',
      drumAsset: _drum80,
      atmosphereAsset: _vinyl,
      neuroAsset: _alpha,
      melodyPool: [_melPiano, _melGuitar, _melAcoustic], // Uses all 3
      pitch: 1.0,
    ),

    // 2. MIDNIGHT STUDY (Darker Vibe)
    Station(
      id: 'dark_mode',
      name: 'Midnight Study',
      description: 'Slowed for deep work',
      drumAsset: _drum80,
      atmosphereAsset: _rainFallback, // Uses vinyl since rain is missing
      neuroAsset: _alpha,
      melodyPool: [_melPiano, _melGuitar], // Excludes the bright acoustic
      pitch: 0.85, // SLOWED DOWN (Vaporwave style)
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
      pitch: 1.05, // SPEEDED UP (Slightly)
    ),
  ];
}