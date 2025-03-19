import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;

class RestaurantOwnerScreen extends StatefulWidget {
  const RestaurantOwnerScreen({super.key});

  @override
  State<RestaurantOwnerScreen> createState() => _RestaurantOwnerScreenState();
}

class _RestaurantOwnerScreenState extends State<RestaurantOwnerScreen> {
  List<dynamic> restaurantOrders = [];
  bool isLoading = true;
  final Map<String, bool> _confirmLoading = {};
  int _selectedIndex = 4; // Default to Owner tab (index 4)

  @override
  void initState() {
    super.initState();
    _fetchRestaurantOrders();
  }

  Future<void> _fetchRestaurantOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.getRestaurantOrders();
      if (mounted) {
        setState(() {
          restaurantOrders = response.where((order) => order['status'] == 'pending').toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _confirmOrder(String orderId) async {
    setState(() => _confirmLoading[orderId] = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateOrderStatus(orderId, 'confirmed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order confirmed'), backgroundColor: accentColor),
        );
        await _fetchRestaurantOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _confirmLoading[orderId] = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/restaurants');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/orders');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 4:
        // Stay on RestaurantOwnerScreen (no navigation needed)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Dashboard', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : _fetchRestaurantOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Orders',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        '${restaurantOrders.length} order${restaurantOrders.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: restaurantOrders.isEmpty
                        ? Center(child: Text('No pending orders', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))))
                        : ListView.builder(
                            itemCount: restaurantOrders.length,
                            itemBuilder: (context, index) {
                              final order = restaurantOrders[index];
                              final orderId = order['id'].toString();
                              final isConfirming = _confirmLoading[orderId] ?? false;
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    'Order #$orderId',
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total: \$${order['total'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 14)),
                                      Text(
                                        'Address: ${order['address'] ?? 'Unknown'}',
                                        style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                  trailing: isConfirming
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed: () => _confirmOrder(orderId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text('Confirm', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Owner',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}