class Station {
  final String id;
  final String name;
  final String brand;
  final String address;
  final String city;
  final double latitude;
  final double longitude;

  const Station({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
