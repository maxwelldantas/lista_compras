class ShoppingItem {
  final String name;
  final double price;
  final int quantity;

  ShoppingItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> map) => ShoppingItem(
    name: map['name'],
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'],
  );
}
