import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main.dart';

class RestaurantOwnerScreen extends StatefulWidget {
  const RestaurantOwnerScreen({super.key});

  @override
  State<RestaurantOwnerScreen> createState() => _RestaurantOwnerScreenState();
}

class _RestaurantOwnerScreenState extends State<RestaurantOwnerScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> restaurantOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantOrders();
  }

  Future<void> _fetchRestaurantOrders() async {
    try {
      // Assuming an endpoint like /restaurant/orders exists
      final response = await apiService.getOrders(); // Placeholder; replace with restaurant-specific API
      setState(() {
        restaurantOrders = response.where((order) => order['status'] == 'pending').toList(); // Example filter
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Orders',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: restaurantOrders.isEmpty
                        ? const Center(child: Text('No pending orders'))
                        : ListView.builder(
                            itemCount: restaurantOrders.length,
                            itemBuilder: (context, index) {
                              final order = restaurantOrders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text('Order #${order['id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total: \$${order['total']}', style: GoogleFonts.poppins()),
                                      Text('Address: ${order['address']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {}, // Add logic to confirm order
                                    child: const Text('Confirm'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}