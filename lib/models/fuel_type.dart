enum FuelType {
  diesel,
  petrol95,
  petrol98,
  electric;

  String get displayName {
    switch (this) {
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.petrol95:
        return 'Bensin 95';
      case FuelType.petrol98:
        return 'Bensin 98';
      case FuelType.electric:
        return 'Elektrisk';
    }
  }

  String get unit {
    switch (this) {
      case FuelType.electric:
        return 'kWh';
      default:
        return 'L';
    }
  }
}
