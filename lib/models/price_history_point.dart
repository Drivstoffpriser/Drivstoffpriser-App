class PriceHistoryPoint {
  final DateTime date;
  final double price;

  const PriceHistoryPoint({required this.date, required this.price});

  factory PriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PriceHistoryPoint(
      date: DateTime.parse(json['date'] as String),
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'price': price,
    };
  }
}
