import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class ApiService {
  static const String baseUrl = 'https://plus.apexjets.org/api'; // Your Laravel API URL
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String googlePlacesUrl = 'https://maps.googleapis.com/maps/api/place';
  static String get googleApiKey => dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_GOOGLE_API_KEY';
  String? _token;

  ApiService();

  void setToken(String token) {
    _token = token;
    print('ApiService: Token set to $_token');
  }

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _handleResponse(http.Response response, {String action = 'API request'}) async {
    print('$action Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    }
    throw Exception('$action failed: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final body = json.encode({'name': name, 'email': email, 'password': password, 'role': role});
    print('ApiService: Register Request - URL: $baseUrl/register, Headers: $headers, Body: $body');
    final response = await http.post(Uri.parse('$baseUrl/register'), headers: headers, body: body);
    return await _handleResponse(response, action: 'Register');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = json.encode({'email': email, 'password': password});
    print('ApiService: Login Request - URL: $baseUrl/login, Headers: $headers, Body: $body');
    final response = await http.post(Uri.parse('$baseUrl/login'), headers: headers, body: body);
    return await _handleResponse(response, action: 'Login');
  }

  Future<Map<String, dynamic>> loginWithGoogle(String email, String accessToken) async {
    final body = json.encode({'email': email, 'google_token': accessToken});
    print('ApiService: Google Login Request - URL: $baseUrl/google-login, Headers: $headers, Body: $body');
    final response = await http.post(Uri.parse('$baseUrl/google-login'), headers: headers, body: body);
    return await _handleResponse(response, action: 'Google Login');
  }

  Future<void> logout() async {
    print('ApiService: Logout Request - URL: $baseUrl/logout, Headers: $headers');
    final response = await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    await _handleResponse(response, action: 'Logout');
    _token = null;
  }

  Future<Map<String, dynamic>> getProfile() async {
    print('ApiService: Fetching profile - URL: $baseUrl/profile, Headers: $headers');
    final response = await http.get(Uri.parse('$baseUrl/profile'), headers: headers);
    final data = await _handleResponse(response, action: 'Get Profile');
    print('ApiService: Profile Data - $data');
    return data;
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email, {String? deliveryLocation}) async {
    final body = json.encode({
      'name': name,
      'email': email,
      if (deliveryLocation != null) 'delivery_location': deliveryLocation,
    });
    print('ApiService: Update Profile Request - URL: $baseUrl/profile, Headers: $headers, Body: $body');
    final response = await http.put(Uri.parse('$baseUrl/profile'), headers: headers, body: body);
    final data = await _handleResponse(response, action: 'Update Profile');
    print('ApiService: Update Profile Response - $data');
    return data;
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    final body = json.encode({'role': newRole});
    print('ApiService: Upgrade Role Request - URL: $baseUrl/upgrade-role, Headers: $headers, Body: $body');
    final response = await http.post(Uri.parse('$baseUrl/upgrade-role'), headers: headers, body: body);
    return await _handleResponse(response, action: 'Upgrade Role');
  }

  Future<List<Map<String, dynamic>>> getRestaurantsFromOverpass({
    double south = 4.0,
    double west = 2.0,
    double north = 14.0,
    double east = 15.0,
  }) async {
    try {
      final query = '[out:json];node["amenity"="restaurant"]($south,$west,$north,$east);out;';
      final url = '$overpassUrl?data=${Uri.encodeQueryComponent(query)}';
      print('ApiService: Overpass Request - URL: $url');
      final overpassResponse = await http.get(Uri.parse(url));
      final overpassData = await _handleResponse(overpassResponse, action: 'Overpass Fetch');
      final elements = overpassData['elements'] as List<dynamic>;
      List<Map<String, dynamic>> restaurants = [];

      for (var restaurant in elements) {
        final name = restaurant['tags']['name'] ?? 'Unnamed Restaurant';
        final lat = restaurant['lat'].toString();
        final lon = restaurant['lon'].toString();

        String? imageUrl;
        final googleUrl = '$googlePlacesUrl/nearbysearch/json?location=$lat,$lon&radius=500&type=restaurant&keyword=$name&key=$googleApiKey';
        print('ApiService: Google Places Request - URL: $googleUrl');
        final googleResponse = await http.get(Uri.parse(googleUrl));
        if (googleResponse.statusCode == 200) {
          final googleData = json.decode(googleResponse.body);
          if (googleData['results'].isNotEmpty && googleData['results'][0]['photos'] != null) {
            final photoReference = googleData['results'][0]['photos'][0]['photo_reference'];
            imageUrl = '$googlePlacesUrl/photo?maxwidth=400&photoreference=$photoReference&key=$googleApiKey';
          }
        } else {
          print('ApiService: Google Places Error - Status: ${googleResponse.statusCode}');
        }

        restaurants.add({
          'id': restaurant['id'].toString(),
          'name': name,
          'lat': lat,
          'lon': lon,
          'image': imageUrl ?? 'https://via.placeholder.com/300',
          'tags': restaurant['tags'],
        });
      }
      print('ApiService: Overpass Restaurants - $restaurants');
      return restaurants;
    } catch (e) {
      print('ApiService: Overpass Fetch Error: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getBoundingBox(String location) async {
    print('ApiService: Getting bounding box for location: $location');
    final locations = await locationFromAddress(location);
    if (locations.isEmpty) throw Exception('Location not found');
    final lat = locations.first.latitude;
    final lon = locations.first.longitude;
    const delta = 0.45; // ~50km
    final result = {'south': lat - delta, 'west': lon - delta, 'north': lat + delta, 'east': lon + delta};
    print('ApiService: Bounding Box - $result');
    return result;
  }

  Future<List<dynamic>> getOrders() async {
    print('ApiService: Fetching orders - URL: $baseUrl/orders, Headers: $headers');
    final response = await http.get(Uri.parse('$baseUrl/orders'), headers: headers);
    final data = await _handleResponse(response, action: 'Get Orders');
    return data is List ? data : data['orders'] ?? [];
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    final body = json.encode(orderData);
    print('ApiService: Place Order Request - URL: $baseUrl/orders, Headers: $headers, Body: $body');
    final response = await http.post(Uri.parse('$baseUrl/orders'), headers: headers, body: body);
    return await _handleResponse(response, action: 'Place Order');
  }

  Future<void> updateOrderPaymentStatus(String orderId, String status) async {
    final body = json.encode({'status': status});
    print('ApiService: Update Order Payment Status - URL: $baseUrl/orders/$orderId/payment-status, Headers: $headers, Body: $body');
    final response = await http.put(Uri.parse('$baseUrl/orders/$orderId/payment-status'), headers: headers, body: body);
    await _handleResponse(response, action: 'Update Order Payment Status');
  }

  Future<void> cancelOrder(String orderId) async {
    print('ApiService: Cancel Order Request - URL: $baseUrl/orders/$orderId/cancel, Headers: $headers');
    final response = await http.post(Uri.parse('$baseUrl/orders/$orderId/cancel'), headers: headers);
    await _handleResponse(response, action: 'Cancel Order');
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    print('ApiService: Get Order Tracking - URL: $baseUrl/orders/track/$trackingNumber, Headers: $headers');
    final response = await http.get(Uri.parse('$baseUrl/orders/track/$trackingNumber'), headers: headers);
    return await _handleResponse(response, action: 'Get Order Tracking');
  }

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
    final body = json.encode({
      'name': name,
      'address': address,
      'state': state,
      'country': country,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'image': image,
      'menu_items': menuItems,
    });
    print('ApiService: Add Restaurant Request - URL: $baseUrl/restaurants, Headers: $headers, Body: $body');
    final response = await http.post(Uri.parse('$baseUrl/restaurants'), headers: headers, body: body);
    return await _handleResponse(response, action: 'Add Restaurant');
  }

  Future<List<dynamic>> getRestaurantsFromApi() async {
    print('ApiService: Fetching restaurants - URL: $baseUrl/restaurants, Headers: $headers');
    try {
      final response = await http.get(Uri.parse('$baseUrl/restaurants'), headers: headers);
      final decoded = await _handleResponse(response, action: 'Get Restaurants from API');
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic>) {
        return decoded['restaurants'] ?? decoded['data'] ?? [];
      }
      throw Exception('Unexpected response format: ${decoded.runtimeType}');
    } catch (e, stackTrace) {
      print('ApiService: GetRestaurantsFromApi Error: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurantOrders() async {
    print('ApiService: Fetching restaurant orders - URL: $baseUrl/restaurant-orders, Headers: $headers');
    final response = await http.get(Uri.parse('$baseUrl/restaurant-orders'), headers: headers);
    final data = await _handleResponse(response, action: 'Get Restaurant Orders');
    return data is List ? data : data['orders'] ?? [];
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final body = json.encode({'status': status});
    print('ApiService: Update Order Status - URL: $baseUrl/orders/$orderId/status, Headers: $headers, Body: $body');
    final response = await http.put(Uri.parse('$baseUrl/orders/$orderId/status'), headers: headers, body: body);
    await _handleResponse(response, action: 'Update Order Status');
  }
}