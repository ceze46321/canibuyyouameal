import 'package:flutter/foundation.dart';
import 'services/api_service.dart';
import 'dart:convert'; // Added for json.encode

class Item {
  final String name;
  final double price;
  final String restaurantName;

  Item({required this.name, required this.price, required this.restaurantName});

  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'restaurantName': restaurantName};
}

class Cart with ChangeNotifier {
  final List<Item> _items = [];
  List<Item> get items => _items;
  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void addItem(String name, double price, String restaurantName) {
    _items.add(Item(name: name, price: price, restaurantName: restaurantName));
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
class OrderProvider with ChangeNotifier {
  final ApiService apiService = ApiService();

  Future<void> addOrder(List<Item> items, double total, {String notes = '', bool isRush = false}) async {
    try {
      final orderData = {
        'items': items.map((item) => item.toJson()).toList(),
        'total': total,
        'notes': notes,
        'is_rush': isRush,
      };
      print('Sending order: ${json.encode(orderData)}');
      final response = await apiService.placeOrder(
        orderData['items'] as List<Map<String, dynamic>>,
        total,
        notes: notes,
        isRush: isRush,
      );
      print('Order response: $response');
      notifyListeners();
    } catch (e) {
      print('Order error: $e');
      throw Exception('Failed to place order: $e'); // This triggers the SnackBar in CartScreen
    }
  }
}