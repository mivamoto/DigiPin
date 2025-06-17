class DigipinEntry {
  final String digipin;
  final double latitude;
  final double longitude;

  DigipinEntry({
    required this.digipin,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'digipin': digipin,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory DigipinEntry.fromJson(Map<String, dynamic> json) => DigipinEntry(
    digipin: json['digipin'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}
