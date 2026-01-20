import '../model/station.dart';

class StationData {
  // Define your paths constants so we don't make typos
  static const _drum80 = 'assets/audio/pool/drums/drum_80bpm_1.ogg';
  static const _vinyl = 'assets/audio/pool/atmosphere/vinyl.ogg';
  static const _rain = 'assets/audio/pool/atmosphere/rain.ogg'; // Assume you have this, or use vinyl
  static const _alpha = 'assets/audio/neuro/alpha_10hz.ogg';

  static const _mel1 = 'assets/audio/pool/melodies/piano_cmin.ogg';
  static const _mel2 = 'assets/audio/pool/melodies/guitar_dmaj.ogg';
  static const _mel3 = 'assets/audio/pool/melodies/acoustic_cmaj.ogg';

  static final List<Station> allStations = [
    // CHANNEL 1: The Standard Chill
    Station(
      id: 'chill_hop',
      name: 'Chill Hop FM',
      description: 'Classic Focus Beats',
      drumAsset: _drum80,
      atmosphereAsset: _vinyl,
      neuroAsset: _alpha,
      melodyPool: [_mel1, _mel2, _mel3], // Uses ALL your melodies
      pitch: 1.0,
    ),

    // CHANNEL 2: Dark Study (Reusing same files, but slowed down!)
    Station(
      id: 'dark_mode',
      name: 'Midnight Study',
      description: 'Slowed & Reverb for deep work',
      drumAsset: _drum80,
      atmosphereAsset: _rain, // If you have rain, or use vinyl
      neuroAsset: _alpha,
      melodyPool: [_mel1, _mel2], // Only uses the Piano & Guitar, excludes the bright Acoustic
      pitch: 0.85, // <--- THIS MAKES IT A NEW STATION
      volumeDrums: 0.8, // Softer drums
    ),

    // CHANNEL 3: Morning Coffee (Brighter)
    Station(
      id: 'morning_vibes',
      name: 'Morning Coffee',
      description: 'Upbeat start',
      drumAsset: _drum80,
      atmosphereAsset: _vinyl,
      neuroAsset: _alpha,
      melodyPool: [_mel2, _mel3], // Only the Major key (Happy) melodies
      pitch: 1.05, // Slightly faster/brighter
    ),
  ];
}