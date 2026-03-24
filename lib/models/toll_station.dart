class TollStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  TollStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory TollStation.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final id = json['id'];
    final name = tags['name'] as String? ?? 'Toll Gantry';

    return TollStation(
      id: 'toll_$id',
      name: name,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
    );
  }
}
