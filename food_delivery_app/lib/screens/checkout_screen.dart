import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:html' as html; // Web-specific functionality
import 'package:flutter_stripe/flutter_stripe.dart' as stripe if (dart.library.io) 'package:flutter_stripe/flutter_stripe.dart'; // Alias for Stripe
import '../auth_provider.dart';
import '../models/cart.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';
import 'restaurant_screen.dart'; // Import for navigation

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'flutterwave'; // Default to Flutterwave for web safety
  bool _isLoading = false;
  int _selectedIndex = 3; // Orders tab as default for Checkout
  static const bool _isWeb = identical(0, 0.0); // True on web, false on native

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    if (!_isWeb) {
      stripe.Stripe.publishableKey = 'pk_test_51R3VqwFo5xO98pwdjgCiM3rXeI9My0RcZHHEZPJXipbsjZ80ydOnprPsBQZQ9GEmY6aTARgWb7tWxofFLTGqINfq00seIuXSDB'; // Use alias
    }
  }

  Future<void> _handleCheckout(AuthProvider auth) async {
    setState(() => _isLoading = true);
    try {
      final response = await auth.initiateOrder(_paymentMethod);
      final order = response['order'] as Map<String, dynamic>?;
      final orderId = order?['id'].toString();

      if (orderId == null) throw Exception('Order ID not returned');

      if (_paymentMethod == 'stripe') {
        if (_isWeb) {
          throw Exception('Stripe payments are not supported on web. Use Flutterwave.');
        }
        final clientSecret = response['client_secret'] as String?;
        if (clientSecret == null) throw Exception('Stripe client secret not returned');

        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Chiw Express',
            allowsDelayedPaymentMethods: true,
          ),
        );
        await stripe.Stripe.instance.presentPaymentSheet();
        await auth.confirmOrderPayment(orderId, 'completed');
        _showSuccessMessage('Payment successful! Order placed.');
      } else if (_paymentMethod == 'flutterwave') {
        final paymentLink = response['payment_link'] as String?;
        if (paymentLink == null) throw Exception('Flutterwave payment link not returned');

        if (await canLaunchUrl(Uri.parse(paymentLink))) {
          await launchUrl(Uri.parse(paymentLink), mode: LaunchMode.externalApplication);
          _showFlutterwavePendingMessage(orderId);

          if (_isWeb) {
            html.window.onMessage.listen((event) {
              if (event.data['type'] == 'payment_complete' && event.data['orderId'] == orderId) {
                final status = event.data['status'] ?? 'completed';
                Navigator.pushReplacementNamed(
                  context,
                  '/orders',
                  arguments: {'orderId': orderId, 'status': status},
                );
              }
            });
          }

          final status = await auth.pollOrderStatus(orderId);
          if (status != null) {
            Navigator.pushReplacementNamed(
              context,
              '/orders',
              arguments: {'orderId': orderId, 'status': status},
            );
          }
        } else {
          throw Exception('Could not launch $paymentLink');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: doorDashRed,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showFlutterwavePendingMessage(String orderId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complete payment in browser, then click Return or wait.', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: doorDashRed,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Orders',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/orders', arguments: {'orderId': orderId});
            },
          ),
        ),
      );
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
    if (index != 3 && routes.containsKey(index)) { // 3 is Checkout (Orders)
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: doorDashLightGrey,
        appBar: AppBar(
          title: Text('Checkout', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: doorDashRed,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(fontSize: 18, color: doorDashGrey),
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

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: doorDashRed,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: auth.cartItems
                            .map((item) => _buildCartItem(item).animate().fadeIn(duration: 300.ms))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Text(
                        '₦${auth.cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: doorDashRed),
                      ),
                    ],
                  ).animate().slideX(duration: 300.ms),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Method',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Select Payment Method',
                      labelStyle: GoogleFonts.poppins(color: doorDashGrey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: doorDashGrey.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: doorDashGrey.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: doorDashRed),
                      ),
                    ),
                    isExpanded: true,
                    items: (_isWeb ? ['flutterwave'] : ['stripe', 'flutterwave'])
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method.capitalize(), style: GoogleFonts.poppins(color: textColor)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ).animate().fadeIn(duration: 300.ms),
                  if (_isWeb)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Stripe is only available on mobile.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _handleCheckout(auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doorDashRed,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ).animate().scale(duration: 300.ms),
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

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
                ),
                Text(
                  'Qty: ${item.quantity} • ${item.restaurantName ?? 'Unknown'}',
                  style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                ),
              ],
            ),
          ),
          Text(
            '₦${(item.price * item.quantity).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 16, color: doorDashRed),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}