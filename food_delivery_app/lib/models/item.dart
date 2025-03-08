import 'package:flutter/material.dart';

class Item {
  final String name;
  final double price;
  final String restaurantName;

  Item({
    required this.name,
    required this.price,
    required this.restaurantName,
  });
}

class Cart with ChangeNotifier {
  final List<Item> _items = [];

  List<Item> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void addItem(String name, double price, String restaurantName) {
    _items.add(Item(name: name, price: price, restaurantName: restaurantName));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class Order {
  final String id;
  final List<Item> items; // Now uses Item
  final double total;
  String status;
  final DateTime placedAt;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.placedAt,
  });
}

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => _orders;

  void addOrder(List<Item> items, double total) {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: items,
      total: total,
      status: 'Placed',
      placedAt: DateTime.now(),
    );
    _orders.add(order);
    notifyListeners();

    Future.delayed(Duration(seconds: 5), () {
      order.status = 'Preparing';
      notifyListeners();
    });
    Future.delayed(Duration(seconds: 10), () {
      order.status = 'Out for Delivery';
      notifyListeners();
    });
    Future.delayed(Duration(seconds: 15), () {
      order.status = 'Delivered';
      notifyListeners();
    });
  }
}