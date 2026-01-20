class Station {
  final String id;
  final String name;
  final String description;

  // The Audio Ingredients
  final String drumAsset;
  final String atmosphereAsset;
  final String neuroAsset;
  final List<String> melodyPool; // The list of compatible melodies to shuffle

  // The "Vibe" Settings
  final double pitch; // 1.0 = Normal, 0.8 = Dark/Slowed
  final double volumeDrums;
  final double volumeMelody;

  const Station({
    required this.id,
    required this.name,
    required this.description,
    required this.drumAsset,
    required this.atmosphereAsset,
    required this.neuroAsset,
    required this.melodyPool,
    this.pitch = 1.0,
    this.volumeDrums = 1.0,
    this.volumeMelody = 1.0,
  });
}