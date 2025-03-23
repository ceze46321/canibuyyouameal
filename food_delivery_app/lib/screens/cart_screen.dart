import 'package:flutter/material.dart' as material; // Alias for Material
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../auth_provider.dart';
import 'checkout_screen.dart';
import '../main.dart' show primaryColor, textColor, accentColor;

class CartScreen extends material.StatefulWidget {
  const CartScreen({super.key});

  @override
  material.State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends material.State<CartScreen> {
  static const material.Color doorDashRed = material.Color(0xFFEF2A39);
  static const material.Color doorDashGrey = material.Color(0xFF757575);
  static const material.Color doorDashLightGrey = material.Color(0xFFF5F5F5);
  static const material.Color doorDashWhite = material.Color(0xFFFFFFFF);

  int _selectedIndex = 3; // Set to Orders tab (index 3 in new navigation)
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = const String.fromEnvironment('STRIPE_KEY', defaultValue: 'your_stripe_publishable_key');
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/groceries',
      3: '/orders', // Current screen
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 3 && routes.containsKey(index)) {
      material.Navigator.pushReplacementNamed(context, routes[index]!); // Fixed
    }
  }

  Future<void> _checkoutWithStripe(AuthProvider auth) async {
    setState(() => _isProcessing = true);
    try {
      final response = await auth.initiateOrder('stripe');
      final order = response['order'];
      final clientSecret = response['client_secret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Chiw Express',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await auth.confirmOrderPayment(order['id'].toString(), 'completed');
      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('Order placed! Tracking: ${order['tracking_number']}', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: doorDashRed,
            behavior: material.SnackBarBehavior.floating,
            shape: material.RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(8)),
          ),
        );
        auth.clearCart();
        material.Navigator.pushReplacementNamed(context, '/orders'); // Fixed
      }
    } catch (e) {
      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('Error: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: material.Colors.redAccent,
            behavior: material.SnackBarBehavior.floating,
            shape: material.RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _checkoutWithFlutterwave() async {
    material.Navigator.push( // Fixed
      context,
      material.MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  @override
  material.Widget build(material.BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return material.Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: material.AppBar(
        backgroundColor: doorDashRed,
        elevation: 0,
        leading: material.IconButton(
          icon: const material.Icon(material.Icons.arrow_back_ios, color: doorDashWhite, size: 20),
          onPressed: () => material.Navigator.pop(context), // Fixed
        ),
        title: material.Text(
          'Your Cart',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: material.FontWeight.w600,
            color: doorDashWhite,
          ),
        ),
        centerTitle: true,
        flexibleSpace: material.Container(
          decoration: material.BoxDecoration(
            gradient: material.LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
              begin: material.Alignment.topCenter,
              end: material.Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: auth.cartItems.isEmpty
          ? material.Center(
              child: material.Text(
                'Your cart is empty',
                style: GoogleFonts.poppins(fontSize: 18, color: doorDashGrey),
              ),
            )
          : material.Column(
              children: [
                material.Expanded(
                  child: material.ListView.builder(
                    padding: const material.EdgeInsets.all(16.0),
                    itemCount: auth.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = auth.cartItems[index];
                      return material.Card(
                        elevation: 2,
                        shape: material.RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(12)),
                        margin: const material.EdgeInsets.only(bottom: 12.0),
                        child: material.Padding(
                          padding: const material.EdgeInsets.all(12.0),
                          child: material.Row(
                            children: [
                              material.Expanded(
                                child: material.Column(
                                  crossAxisAlignment: material.CrossAxisAlignment.start,
                                  children: [
                                    material.Text(
                                      item.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: material.FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const material.SizedBox(height: 4),
                                    material.Text(
                                      item.restaurantName ?? 'Unknown Restaurant',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: doorDashGrey,
                                      ),
                                    ),
                                    const material.SizedBox(height: 4),
                                    material.Text(
                                      '\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              material.IconButton(
                                icon: const material.Icon(material.Icons.delete, color: material.Colors.redAccent),
                                onPressed: () => auth.removeFromCart(item.name),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                material.Container(
                  color: doorDashWhite,
                  padding: const material.EdgeInsets.all(16.0),
                  child: material.Column(
                    children: [
                      material.Row(
                        mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                        children: [
                          material.Text(
                            'Total:',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: material.FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          material.Text(
                            '\$${auth.cartTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: material.FontWeight.bold,
                              color: doorDashRed,
                            ),
                          ),
                        ],
                      ),
                      const material.SizedBox(height: 16),
                      _isProcessing
                          ? const material.Center(child: material.CircularProgressIndicator(color: doorDashRed))
                          : material.Column(
                              children: [
                                material.ElevatedButton(
                                  onPressed: () => _checkoutWithStripe(auth),
                                  style: material.ElevatedButton.styleFrom(
                                    backgroundColor: doorDashRed,
                                    minimumSize: const material.Size(double.infinity, 50),
                                    shape: material.RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(12)),
                                  ),
                                  child: material.Text(
                                    'Checkout with Stripe',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: doorDashWhite,
                                    ),
                                  ),
                                ),
                                const material.SizedBox(height: 12),
                                material.ElevatedButton(
                                  onPressed: _checkoutWithFlutterwave,
                                  style: material.ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    minimumSize: const material.Size(double.infinity, 50),
                                    shape: material.RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(12)),
                                  ),
                                  child: material.Text(
                                    'Checkout with Flutterwave',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: doorDashWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: material.BottomNavigationBar(
        items: const [
          material.BottomNavigationBarItem(icon: material.Icon(material.Icons.home), label: 'Home'),
          material.BottomNavigationBarItem(icon: material.Icon(material.Icons.restaurant), label: 'Restaurants'),
          material.BottomNavigationBarItem(icon: material.Icon(material.Icons.local_grocery_store), label: 'Groceries'),
          material.BottomNavigationBarItem(icon: material.Icon(material.Icons.shopping_cart), label: 'Orders'),
          material.BottomNavigationBarItem(icon: material.Icon(material.Icons.person), label: 'Profile'),
          material.BottomNavigationBarItem(icon: material.Icon(material.Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        backgroundColor: doorDashWhite,
        type: material.BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: material.FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
      ),
    );
  }
}