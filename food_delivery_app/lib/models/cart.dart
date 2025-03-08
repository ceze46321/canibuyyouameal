import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double price;
  final String restaurantName;

  CartItem({
    required this.name,
    required this.price,
    required this.restaurantName,
  });
}

class Cart with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void addItem(String name, double price, String restaurantName) {
    _items.add(CartItem(name: name, price: price, restaurantName: restaurantName));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}