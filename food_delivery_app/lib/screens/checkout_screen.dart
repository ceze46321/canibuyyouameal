import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html; // Add for web-specific functionality
// Import flutter_stripe only if not on web
import 'package:flutter_stripe/flutter_stripe.dart' if (dart.library.io) 'package:flutter_stripe/flutter_stripe.dart';
import '../auth_provider.dart';
import '../models/cart.dart';
import '../main.dart' show primaryColor, textColor, accentColor, secondaryColor;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'flutterwave'; // Default to Flutterwave for web safety
  bool _isLoading = false;
  static const bool _isWeb = identical(0, 0.0); // True on web, false on native

  @override
  void initState() {
    super.initState();
    if (!_isWeb) {
      Stripe.publishableKey = 'pk_test_51R3VqwFo5xO98pwdjgCiM3rXeI9My0RcZHHEZPJXipbsjZ80ydOnprPsBQZQ9GEmY6aTARgWb7tWxofFLTGqINfq00seIuXSDB'; // Replace with your key
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

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Chiw Express',
            allowsDelayedPaymentMethods: true,
          ),
        );
        await Stripe.instance.presentPaymentSheet();
        await auth.confirmOrderPayment(orderId, 'completed');
        _showSuccessMessage('Payment successful! Order placed.');
      } else if (_paymentMethod == 'flutterwave') {
        final paymentLink = response['payment_link'] as String?;
        if (paymentLink == null) throw Exception('Flutterwave payment link not returned');

        if (await canLaunchUrl(Uri.parse(paymentLink))) {
          await launchUrl(Uri.parse(paymentLink), mode: LaunchMode.externalApplication);
          _showFlutterwavePendingMessage(orderId);

          // Web-specific: Listen for payment completion
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

          // Polling as fallback
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
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
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
        SnackBar(content: Text(message), backgroundColor: accentColor),
      );
      Navigator.pop(context);
    }
  }

  void _showFlutterwavePendingMessage(String orderId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete payment in browser, then click Return or wait.'),
          backgroundColor: accentColor,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Orders',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/orders', arguments: {'orderId': orderId});
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Checkout', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(fontSize: 18, color: textColor),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  ...auth.cartItems.map((item) => _buildCartItem(item)).toList(),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        '\$${auth.cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Method',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _paymentMethod,
                    isExpanded: true,
                    items: (_isWeb
                            ? ['flutterwave']
                            : ['stripe', 'flutterwave'])
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method, style: GoogleFonts.poppins(color: textColor)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
                  if (_isWeb)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Stripe is only available on mobile.',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _handleCheckout(auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        'Pay Now',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
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
                  style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                ),
                Text(
                  'Qty: ${item.quantity} • ${item.restaurantName ?? 'Unknown'}',
                  style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 16, color: accentColor),
          ),
        ],
      ),
    );
  }
}