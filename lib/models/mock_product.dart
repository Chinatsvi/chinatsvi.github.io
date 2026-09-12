class MockProduct {
  final String id;
  final String title;
  final String description;
  final double price;

  MockProduct(this.id, this.title, this.description, this.price);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
      };
}

final mockProducts = [
  MockProduct(
    'verification_tick_monthly',
    'Verification Tick (30 days)',
    'Renew your tick for 30 days',
    29.99,
  ),
  MockProduct(
    'boost_7days',
    'Boost Post (7 days)',
    'Boost your post for 7 days',
    19.99,
  ),
];
