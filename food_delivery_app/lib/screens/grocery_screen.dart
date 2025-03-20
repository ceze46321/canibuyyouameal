import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../services/api_service.dart'; // Import ApiService
import 'restaurant_screen.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 2; // Groceries tab
  List<dynamic> groceries = [];
  List<dynamic> filteredGroceries = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedLocation = 'All';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fetchGroceries();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroceries() async {
    setState(() => isLoading = true);
    try {
      final data = await _apiService.getGroceries();
      setState(() {
        groceries = data;
        filteredGroceries = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading groceries: $e')),
      );
    }
  }

  void _filterGroceries() {
    setState(() {
      filteredGroceries = groceries.where((item) {
        final matchesName = item['items'].any((i) => i['name'].toLowerCase().contains(searchQuery.toLowerCase()));
        // Add location filter if your API supports it; for now, we'll skip it
        return matchesName;
      }).toList();
    });
  }

  void _addToCart(dynamic grocery) {
    setState(() {
      for (var item in grocery['items']) {
        cart.add({
          'id': grocery['id'],
          'name': item['name'],
          'price': item['price'],
          'quantity': 1,
          'image': item['image'],
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Items from grocery #${grocery['id']} added to cart!'), backgroundColor: accentColor),
    );
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      final groceryItems = cart.map((item) => ({
            'name': item['name'],
            'quantity': item['quantity'],
            'price': item['price'],
            'image': item['image'],
          })).toList();

      final newGrocery = await _apiService.createGrocery(groceryItems);
      final groceryId = newGrocery['id'].toString();

      final paymentUrl = await _apiService.initiateCheckout(groceryId);
      if (await canLaunch(paymentUrl)) {
        await launch(paymentUrl);
        setState(() => cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiated!'), backgroundColor: accentColor),
        );
      } else {
        throw 'Could not launch $paymentUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 2 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groceries', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _fetchGroceries,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      _filterGroceries();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['All'].map((location) { // Simplified for now; expand if API supports locations
                      return DropdownMenuItem(value: location, child: Text(location, style: GoogleFonts.poppins()));
                    }).toList(),
                    onChanged: (value) {
                      selectedLocation = value!;
                      _filterGroceries();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : filteredGroceries.isEmpty
                      ? Center(child: Text('No groceries found', style: GoogleFonts.poppins(fontSize: 20, color: textColor.withOpacity(0.7))))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredGroceries.length,
                          itemBuilder: (context, index) {
                            final grocery = filteredGroceries[index];
                            return _buildGroceryItem(grocery);
                          },
                        ),
            ),
            if (cart.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cart: ${cart.length} items',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('Checkout', style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildGroceryItem(dynamic grocery) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: grocery['items'].isNotEmpty && grocery['items'][0]['image'] != null
            ? Image.network(
                grocery['items'][0]['image'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: accentColor.withOpacity(0.3),
                  ),
                  child: const Icon(Icons.image_not_supported, color: Colors.white),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accentColor.withOpacity(0.3),
                ),
                child: const Icon(Icons.image_not_supported, color: Colors.white),
              ),
        title: Text(
          'Grocery #${grocery['id']}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          '\$${grocery['total_amount']} - ${grocery['items'].length} items',
          style: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: primaryColor),
          onPressed: () => _addToCart(grocery),
        ),
      ),
    );
  }
}