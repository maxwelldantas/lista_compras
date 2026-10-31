import 'dart:convert';

import 'shopping_item.dart';

class MarketList {
  final int? id;
  final String marketName;
  final String date;
  final String time; // Nova propriedade de horário
  final List<ShoppingItem> items;

  MarketList({
    this.id,
    required this.marketName,
    required this.date,
    required this.time,
    required this.items,
  });

  double get totalPrice =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'marketName': marketName,
    'date': date,
    'time': time,
    'itemsJson': json.encode(items.map((i) => i.toMap()).toList()),
  };

  factory MarketList.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decoded = json.decode(map['itemsJson']);
    return MarketList(
      id: map['id'],
      marketName: map['marketName'],
      date: map['date'],
      time: map['time'] ?? '', // Fallback para registros antigos sem hora
      items: decoded.map((i) => ShoppingItem.fromMap(i)).toList(),
    );
  }
}
