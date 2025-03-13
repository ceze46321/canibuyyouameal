import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://plus.apexjets.org/api';

  Future<List<dynamic>> getRestaurants() async {
    final response = await http.get(Uri.parse('$baseUrl/restaurants'));
    print('Restaurants response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load restaurants: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> getRestaurant(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/restaurants/$id'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load restaurant: ${response.statusCode} - ${response.body}');
  }

  Future<List<dynamic>> getGroceries() async {
    final response = await http.get(Uri.parse('$baseUrl/groceries'));
    print('Groceries response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load groceries: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> placeOrder(List<Map<String, dynamic>> items, double total, {String notes = '', bool isRush = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'items': items, 'total': total, 'notes': notes, 'is_rush': isRush}),
      );
      print('Place order response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          return {'success': true, 'message': 'Order placed successfully, no details returned'};
        }
      }
      throw Exception('Failed to place order: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Place order error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    print('Orders response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load orders: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> updateOrderStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to update order status: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> addRestaurant(String name, String image, String deliveryTime, Map<String, dynamic> menu) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'image': image,
          'delivery_time': deliveryTime,
          'menu': menu,
        }),
      );
      print('Add restaurant response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to add restaurant: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Add restaurant error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addGrocery(String name, String image, double price, String deliveryTime) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groceries'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'image': image,
          'price': price,
          'delivery_time': deliveryTime,
        }),
      );
      print('Add grocery response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to add grocery: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Add grocery error: $e');
      rethrow;
    }
  }
}