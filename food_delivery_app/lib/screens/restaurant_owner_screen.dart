import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';

class RestaurantOwnerScreen extends StatefulWidget {
  const RestaurantOwnerScreen({super.key});

  @override
  State<RestaurantOwnerScreen> createState() => _RestaurantOwnerScreenState();
}

class _RestaurantOwnerScreenState extends State<RestaurantOwnerScreen> {
  List<dynamic> restaurantOrders = [];
  bool isLoading = true;
  final Map<String, bool> _confirmLoading = {};
  int _selectedIndex = 5; // Owner tab as default

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetch();
  }

  Future<void> _checkAccessAndFetch() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isRestaurantOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccessDeniedDialog();
      });
      return;
    }
    await _fetchRestaurantOrders();
  }

  Future<void> _fetchRestaurantOrders() async {
    setState(() => isLoading = true);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching orders: $e', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
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
          SnackBar(
            content: Text('Order confirmed', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: doorDashRed,
          ),
        );
        await _fetchRestaurantOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming order: $e', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirmLoading[orderId] = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/groceries',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 5 && routes.containsKey(index)) { // 5 is Owner
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Access Denied',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        ),
        content: Text(
          'This page is only accessible to restaurant owners. You’ll be redirected to the home screen.',
          style: GoogleFonts.poppins(fontSize: 16, color: doorDashGrey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontSize: 16, color: doorDashRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isRestaurantOwner && !isLoading) {
      return const SizedBox.shrink(); // Dialog handles redirect
    }

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text(
          'Restaurant Dashboard',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : _fetchRestaurantOrders,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 50))
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
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Text(
                        '${restaurantOrders.length} order${restaurantOrders.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Expanded(
                    child: restaurantOrders.isEmpty
                        ? Center(
                            child: Text(
                              'No pending orders',
                              style: GoogleFonts.poppins(fontSize: 16, color: doorDashGrey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: restaurantOrders.length,
                            itemBuilder: (context, index) {
                              final order = restaurantOrders[index];
                              final orderId = order['id'].toString();
                              final isConfirming = _confirmLoading[orderId] ?? false;
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    'Order #$orderId',
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total: ₦${order['total'] ?? 'N/A'}',
                                        style: GoogleFonts.poppins(fontSize: 14, color: doorDashRed),
                                      ),
                                      Text(
                                        'Address: ${order['address'] ?? 'Unknown'}',
                                        style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                                      ),
                                    ],
                                  ),
                                  trailing: isConfirming
                                      ? SpinKitFadingCircle(color: doorDashRed, size: 24)
                                      : ElevatedButton(
                                          onPressed: () => _confirmOrder(orderId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: doorDashRed,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'Confirm',
                                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                                          ),
                                        ),
                                ),
                              ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms);
                            },
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
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
      ),
    );
  }
}