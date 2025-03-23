import 'package:flutter/material.dart';
import 'package:chiw_express/models/cart.dart';
import 'package:chiw_express/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _name;
  String? _email;
  String? _role;
  String? _deliveryLocation;
  List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _groceryProducts = [];
  List<Map<String, dynamic>> _userGroceries = [];
  bool _isLoadingGroceries = false;
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
  List<Map<String, dynamic>> get groceryProducts => _groceryProducts;
  List<Map<String, dynamic>> get userGroceries => _userGroceries;
  bool get isLoadingGroceries => _isLoadingGroceries;
  ApiService get apiService => _apiService;

  AuthProvider() {
    loadToken();
  }

  Future<void> loadToken() async {
    debugPrint('Loading token...');
    if (_isWeb) {
      _token = html.window.localStorage['auth_token'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
    }
    debugPrint('Token loaded: $_token');
    if (_token != null) {
      await _apiService.setToken(_token!);
      _fetchUserData();
    }
    notifyListeners();
  }

  Future<void> _fetchUserData() async {
    if (!isLoggedIn) return;
    try {
      await getProfile();
      debugPrint('Profile fetched successfully');
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    try {
      await fetchGroceryProducts();
      debugPrint('Grocery products fetched successfully');
    } catch (e) {
      debugPrint('Error fetching grocery products: $e');
    }
    try {
      await fetchUserGroceries();
      debugPrint('User groceries fetched successfully');
    } catch (e) {
      debugPrint('Error fetching user groceries: $e');
    }
    notifyListeners();
  }

  // Cart Management Methods (unchanged)
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

  // Authentication Methods (unchanged)
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    try {
      final response = await _apiService.register(name, email, password, role);
      _token = response['token'];
      await _persistToken(_token!);
      await _apiService.setToken(_token!);
      _name = response['user']['name'] ?? name;
      _email = response['user']['email'] ?? email;
      _role = response['user']['role'] ?? role;
      _deliveryLocation = response['user']['delivery_location'];
      _fetchUserData();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Register failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      await _persistToken(_token!);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _fetchUserData();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String email, String accessToken) async {
    try {
      final response = await _apiService.loginWithGoogle(email, accessToken);
      _token = response['token'];
      await _persistToken(_token!);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _fetchUserData();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Google login failed: $e');
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
      _userGroceries.clear();
      if (_isWeb) {
        html.window.localStorage.remove('auth_token');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Logout failed: $e');
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
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Get profile failed: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(String name, String email, {String? deliveryLocation, String? role}) async {
    try {
      final response = await _apiService.updateProfile(
        name,
        email,
        deliveryLocation: deliveryLocation,
        role: role, // Pass role to API
      );
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    try {
      final response = await _apiService.upgradeRole(newRole);
      _role = newRole;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Upgrade role failed: $e');
      rethrow;
    }
  }

  // Grocery Product Management (unchanged)
  Future<List<Map<String, dynamic>>> fetchGroceryProducts() async {
    try {
      final productsData = await _apiService.fetchGroceryProducts();
      debugPrint('Raw grocery products data: $productsData');
      if (productsData == null || productsData.isEmpty) {
        _groceryProducts = [];
      } else {
        _groceryProducts = List<Map<String, dynamic>>.from(productsData);
      }
      debugPrint('Parsed grocery products: $_groceryProducts');
      notifyListeners();
      return _groceryProducts;
    } catch (e) {
      debugPrint('Fetch grocery products failed: $e');
      _groceryProducts = [];
      notifyListeners();
      return _groceryProducts;
    }
  }

  Future<Map<String, dynamic>> createGrocery(List<Map<String, dynamic>> items) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.createGrocery(items);
      await fetchGroceryProducts();
      await fetchUserGroceries();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Create grocery failed: $e');
      rethrow;
    }
  }

  Future<void> deleteGroceryProduct(String groceryId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      await _apiService.deleteGrocery(groceryId);
      await fetchGroceryProducts();
      await fetchUserGroceries();
      notifyListeners();
    } catch (e) {
      debugPrint('Delete grocery product failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateCheckout(String groceryId, {String paymentMethod = 'stripe'}) async {
    try {
      final response = await _apiService.initiateCheckout(groceryId, paymentMethod: paymentMethod);
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Initiate checkout failed: $e');
      rethrow;
    }
  }

  Future<void> fetchUserGroceries() async {
    if (!isLoggedIn) return;
    _isLoadingGroceries = true;
    notifyListeners();

    try {
      final response = await _apiService.fetchUserGroceries();
      _userGroceries = List<Map<String, dynamic>>.from(response).map((grocery) {
        return {
          'id': grocery['id'],
          'total_price': grocery['total_amount'],
          'status': grocery['status'],
          'items': grocery['items'],
          'created_at': grocery['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Fetch user groceries failed: $e');
      _userGroceries = [];
    } finally {
      _isLoadingGroceries = false;
      notifyListeners();
    }
  }

  // Restaurant and Order Management (unchanged)
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
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Add restaurant failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurants() async {
    try {
      return await _apiService.getRestaurantsFromApi();
    } catch (e) {
      debugPrint('Get restaurants failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurantOrders() async {
    try {
      return await _apiService.getRestaurantOrders();
    } catch (e) {
      debugPrint('Get restaurant orders failed: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _apiService.updateOrderStatus(orderId, status);
      notifyListeners();
    } catch (e) {
      debugPrint('Update order status failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      return await _apiService.getOrders();
    } catch (e) {
      debugPrint('Get orders failed: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiService.cancelOrder(orderId);
      notifyListeners();
    } catch (e) {
      debugPrint('Cancel order failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    try {
      return await _apiService.getOrderTracking(trackingNumber);
    } catch (e) {
      debugPrint('Get order tracking failed: $e');
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
      return response;
    } catch (e) {
      debugPrint('Initiate order failed: $e');
      rethrow;
    }
  }

  Future<void> confirmOrderPayment(String orderId, String status) async {
    try {
      await _apiService.updateOrderPaymentStatus(orderId, status);
      if (status == 'completed') {
        clearCart();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Confirm order payment failed: $e');
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
            return status;
          }
        }
        await Future.delayed(interval);
      }
      return null;
    } catch (e) {
      debugPrint('Poll order status failed: $e');
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