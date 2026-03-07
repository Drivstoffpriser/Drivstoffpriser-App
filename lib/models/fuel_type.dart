enum FuelType {
  petrol95,
  petrol98,
  diesel;

  String get displayName {
    switch (this) {
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.petrol95:
        return 'Bensin 95';
      case FuelType.petrol98:
        return 'Bensin 98';
    }
  }

  String get unit => 'L';
}
