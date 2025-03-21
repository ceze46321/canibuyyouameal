import 'package:flutter/material.dart';
import 'package:chiw_express/models/cart.dart';
import 'package:chiw_express/services/api_service.dart';
import 'package:chiw_express/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _name;
  String? _email;
  String? _role;
  String? _deliveryLocation;
  List<CartItem> _cartItems = [];
  List<Product> _groceryProducts = [];
  static const bool _isWeb = identical(0, 0.0);

  // Getters
  String? get token => _token;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;
  String? get deliveryLocation => _deliveryLocation;
  bool get isLoggedIn => _token != null;
  List<CartItem> get cartItems => _cartItems;
  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  bool get isRestaurantOwner => _role == 'restaurant_owner';
  List<Product> get groceryProducts => _groceryProducts;

  AuthProvider() {
    loadToken();
  }

  Future<void> loadToken() async {
    if (_isWeb) {
      _token = html.window.localStorage['auth_token'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
    }
    if (_token != null) {
      _apiService.setToken(_token!);
      await getProfile();
      await fetchGroceryProducts();
    }
    notifyListeners();
  }

  // Cart Management Methods
  void addToCart(String name, double price, {String? restaurantName, String? id}) {
    final itemId = id ?? name;
    final existingIndex = _cartItems.indexWhere((i) => i.id == itemId);
    if (existingIndex >= 0) {
      _cartItems[existingIndex] = CartItem(
        id: _cartItems[existingIndex].id,
        name: _cartItems[existingIndex].name,
        price: _cartItems[existingIndex].price,
        quantity: _cartItems[existingIndex].quantity + 1,
        restaurantName: _cartItems[existingIndex].restaurantName ?? restaurantName,
      );
    } else {
      _cartItems.add(CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: 1,
        restaurantName: restaurantName,
      ));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String name, double price, int change, {String? restaurantName, String? id}) {
    final itemId = id ?? name;
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final newQuantity = _cartItems[index].quantity + change;
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = CartItem(
          id: _cartItems[index].id,
          name: _cartItems[index].name,
          price: _cartItems[index].price,
          quantity: newQuantity,
          restaurantName: _cartItems[index].restaurantName ?? restaurantName,
        );
      }
    } else if (change > 0) {
      _cartItems.add(CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: change,
        restaurantName: restaurantName,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Authentication Methods
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    try {
      final response = await _apiService.register(name, email, password, role);
      _token = response['token'];
      _name = response['user']['name'] ?? name;
      _email = response['user']['email'] ?? email;
      _role = response['user']['role'] ?? role;
      _deliveryLocation = response['user']['delivery_location'];
      await _persistToken(_token!);
      _apiService.setToken(_token!);
      print('AuthProvider: Register Successful - Token: $_token, Name: $_name, Role: $_role, Delivery Location: $_deliveryLocation');
      await fetchGroceryProducts();
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Register Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      await _persistToken(_token!);
      _apiService.setToken(_token!);
      print('AuthProvider: Login Successful - Token: $_token, Name: $_name, Role: $_role, Delivery Location: $_deliveryLocation');
      await fetchGroceryProducts();
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Login Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String email, String accessToken) async {
    try {
      final response = await _apiService.loginWithGoogle(email, accessToken);
      _token = response['token'];
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      await _persistToken(_token!);
      _apiService.setToken(_token!);
      print('AuthProvider: Google Login Successful - Token: $_token, Name: $_name, Role: $_role, Delivery Location: $_deliveryLocation');
      await fetchGroceryProducts();
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Google Login Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
      _token = null;
      _name = null;
      _email = null;
      _role = null;
      _deliveryLocation = null;
      _cartItems.clear();
      _groceryProducts.clear();
      if (_isWeb) {
        html.window.localStorage.remove('auth_token');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
      print('AuthProvider: Logout Successful');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Logout Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      _name = response['name'];
      _email = response['email'];
      _role = response['role'];
      _deliveryLocation = response['delivery_location'];
      print('AuthProvider: Profile Fetched - Name: $_name, Role: $_role, Delivery Location: $_deliveryLocation');
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Get Profile Error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(String name, String email, {String? deliveryLocation}) async {
    try {
      final response = await _apiService.updateProfile(name, email, deliveryLocation: deliveryLocation);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      print('AuthProvider: Profile Updated - Name: $_name, Delivery Location: $_deliveryLocation');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Update Profile Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    try {
      final response = await _apiService.upgradeRole(newRole);
      _role = newRole;
      print('AuthProvider: Role Upgraded to $_role');
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Upgrade Role Error: $e');
      rethrow;
    }
  }

  // Grocery Product Fetching
  Future<void> fetchGroceryProducts() async {
    try {
      final productsData = await _apiService.fetchGroceryProducts();
      print('AuthProvider: Raw products data: $productsData');
      _groceryProducts = productsData
          .expand((grocery) => (grocery['items'] as List)
              .map((item) => Product.fromJson(item, groceryId: grocery['id'].toString())))
          .toList();
      print('AuthProvider: Mapped products: ${_groceryProducts.map((p) => p.name).toList()}');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Fetch Grocery Products Error: $e');
      _groceryProducts = [];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createGrocery(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiService.createGrocery(items);
      print('AuthProvider: Grocery Created - Response: $response');
      await fetchGroceryProducts();
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Create Grocery Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateCheckout(String groceryId, {String paymentMethod = 'stripe'}) async {
    try {
      final response = await _apiService.initiateCheckout(groceryId, paymentMethod: paymentMethod);
      print('AuthProvider: Checkout Initiated for Grocery $groceryId with $paymentMethod - Response: $response');
      notifyListeners();
      return response; // Returns {client_secret, payment_method} or {payment_link, payment_method}
    } catch (e) {
      print('AuthProvider: Initiate Checkout Error: $e');
      rethrow;
    }
  }

  // Restaurant and Order Management
  Future<Map<String, dynamic>> addRestaurant(
    String name,
    String address,
    String state,
    String country,
    String category, {
    double? latitude,
    double? longitude,
    String? image,
    required List<Map<String, dynamic>> menuItems,
  }) async {
    try {
      final response = await _apiService.addRestaurant(
        name,
        address,
        state,
        country,
        category,
        latitude: latitude,
        longitude: longitude,
        image: image,
        menuItems: menuItems,
      );
      print('AuthProvider: Add Restaurant Response: $response');
      notifyListeners();
      return response;
    } catch (e) {
      print('AuthProvider: Add Restaurant Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurants() async {
    try {
      final result = await _apiService.getRestaurantsFromApi();
      print('AuthProvider: Fetched Restaurants: $result');
      return result;
    } catch (e) {
      print('AuthProvider: Get Restaurants Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurantOrders() async {
    try {
      final result = await _apiService.getRestaurantOrders();
      if (result.isEmpty) {
        print('AuthProvider: No restaurant orders found');
      } else {
        print('AuthProvider: Fetched Restaurant Orders: $result');
      }
      return result;
    } catch (e) {
      print('AuthProvider: Get Restaurant Orders Error: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _apiService.updateOrderStatus(orderId, status);
      print('AuthProvider: Updated Order $orderId to $status');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Update Order Status Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      final result = await _apiService.getOrders();
      if (result.isEmpty) {
        print('AuthProvider: No orders found for user');
      } else {
        print('AuthProvider: Fetched Orders: $result');
      }
      return result;
    } catch (e) {
      print('AuthProvider: Get Orders Error: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiService.cancelOrder(orderId);
      print('AuthProvider: Cancelled Order $orderId');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Cancel Order Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    try {
      final result = await _apiService.getOrderTracking(trackingNumber);
      print('AuthProvider: Fetched Tracking for $trackingNumber: $result');
      return result;
    } catch (e) {
      print('AuthProvider: Get Order Tracking Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateOrder(String paymentMethod) async {
    try {
      if (_cartItems.isEmpty) throw Exception('Cart is empty');
      if (_token == null) throw Exception('User not authenticated');
      final orderData = {
        'items': _cartItems.map((item) => item.toJson()).toList(),
        'total': cartTotal,
        'payment_method': paymentMethod,
      };
      final response = await _apiService.placeOrder(orderData);
      print('AuthProvider: Order Initiated with $paymentMethod - Response: $response');
      return response;
    } catch (e) {
      print('AuthProvider: Initiate Order Error: $e');
      rethrow;
    }
  }

  Future<void> confirmOrderPayment(String orderId, String status) async {
    try {
      await _apiService.updateOrderPaymentStatus(orderId, status);
      if (status == 'completed') {
        clearCart();
      }
      print('AuthProvider: Order Payment Confirmed - Order ID: $orderId, Status: $status');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Confirm Order Payment Error: $e');
      rethrow;
    }
  }

  Future<String?> pollOrderStatus(String orderId, {int maxAttempts = 10, Duration interval = const Duration(seconds: 3)}) async {
    try {
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final orders = await getOrders();
        final order = orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
        if (order != null) {
          final status = order['status'] as String?;
          if (status == 'completed' || status == 'cancelled' || status == 'failed') {
            print('AuthProvider: Order $orderId status updated to $status after polling');
            return status;
          }
        }
        print('AuthProvider: Polling attempt $attempt for Order $orderId - No status update yet');
        await Future.delayed(interval);
      }
      print('AuthProvider: Polling timed out for Order $orderId');
      return null;
    } catch (e) {
      print('AuthProvider: Poll Order Status Error: $e');
      rethrow;
    }
  }

  // Helper method to persist token
  Future<void> _persistToken(String token) async {
    if (_isWeb) {
      html.window.localStorage['auth_token'] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
  }
}