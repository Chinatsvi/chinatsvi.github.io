class BoostPackage {
  final String id;
  final String title;
  final int days;
  final double price;

  BoostPackage({
    required this.id,
    required this.title,
    required this.days,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'days': days,
      'price': price,
    };
  }
}