import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class ApiService {
  static const String baseUrl = 'https://plus.apexjets.org/api';
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String googlePlacesUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String googleApiKey = 'YOUR_GOOGLE_API_KEY'; // Replace with your key
  String? _token;

  void setToken(String token) => _token = token;

  Map<String, String> get headers => {  // Changed from _headers to headers (public getter)
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Added for consistency
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final body = json.encode({'name': name, 'email': email, 'password': password, 'role': role});
    final response = await http.post(Uri.parse('$baseUrl/register'), headers: headers, body: body);
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Registration failed');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = json.encode({'email': email, 'password': password});
    final response = await http.post(Uri.parse('$baseUrl/login'), headers: headers, body: body);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Login failed');
  }

  Future<void> logout() async {
    final response = await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    if (response.statusCode != 200) throw Exception('Failed to logout');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/profile'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load profile');
  }

  Future<void> updateProfile(String name, String email, {Map<String, dynamic>? restaurantDetails}) async {
    final body = json.encode({'name': name, 'email': email, 'restaurant_details': restaurantDetails});
    final response = await http.put(Uri.parse('$baseUrl/profile'), headers: headers, body: body);
    if (response.statusCode != 200) throw Exception('Failed to update profile');
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    final body = json.encode({'role': newRole});
    final response = await http.post(
      Uri.parse('$baseUrl/upgrade-role'),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to upgrade role: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getRestaurants({double south = 4.0, double west = 2.0, double north = 14.0, double east = 15.0}) async {
    try {
      final query = '[out:json];node["amenity"="restaurant"]($south,$west,$north,$east);out;';
      final overpassResponse = await http.get(Uri.parse('$overpassUrl?data=${Uri.encodeQueryComponent(query)}'));
      if (overpassResponse.statusCode != 200) throw Exception('Failed to load from Overpass');

      final overpassData = json.decode(overpassResponse.body)['elements'] as List<dynamic>;
      List<Map<String, dynamic>> restaurants = [];

      for (var restaurant in overpassData) {
        final name = restaurant['tags']['name'] ?? 'Unnamed Restaurant';
        final lat = restaurant['lat'].toString();
        final lon = restaurant['lon'].toString();

        String? imageUrl;
        final googleResponse = await http.get(Uri.parse(
          '$googlePlacesUrl/nearbysearch/json?location=$lat,$lon&radius=500&type=restaurant&keyword=$name&key=$googleApiKey',
        ));
        if (googleResponse.statusCode == 200) {
          final googleData = json.decode(googleResponse.body);
          if (googleData['results'].isNotEmpty && googleData['results'][0]['photos'] != null) {
            final photoReference = googleData['results'][0]['photos'][0]['photo_reference'];
            imageUrl = '$googlePlacesUrl/photo?maxwidth=400&photoreference=$photoReference&key=$googleApiKey';
          }
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
      return restaurants;
    } catch (e) {
      print('Restaurant Fetch Error: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getBoundingBox(String location) async {
    final locations = await locationFromAddress(location);
    if (locations.isEmpty) throw Exception('Location not found');
    final lat = locations.first.latitude;
    final lon = locations.first.longitude;
    const delta = 0.45; // ~50km
    return {'south': lat - delta, 'west': lon - delta, 'north': lat + delta, 'east': lon + delta};
  }

  Future<List<dynamic>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load orders');
  }

  Future<Map<String, dynamic>> placeOrder(List<Map<String, dynamic>> items, String address, {String notes = '', bool isRush = false}) async {
    final body = json.encode({
      'items': items,
      'total': items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])),
      'status': 'pending',
      'notes': notes,
      'is_rush': isRush,
      'address': address,
    });
    final response = await http.post(Uri.parse('$baseUrl/orders'), headers: headers, body: body);
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to place order');
  }

  Future<void> cancelOrder(String orderId) async {
    final response = await http.post(Uri.parse('$baseUrl/orders/$orderId/cancel'), headers: headers);
    if (response.statusCode != 200) throw Exception('Failed to cancel order');
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/track/$trackingNumber'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch tracking info');
  }
}