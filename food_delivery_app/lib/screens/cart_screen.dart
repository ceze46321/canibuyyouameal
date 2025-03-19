import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../auth_provider.dart';
import 'checkout_screen.dart'; // Adjusted import assuming lib/screens/
import '../main.dart' show primaryColor, textColor, accentColor;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _selectedIndex = 2;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = const String.fromEnvironment('STRIPE_KEY', defaultValue: 'your_stripe_publishable_key');
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
        Navigator.pushReplacementNamed(context, '/restaurant-owner');
        break;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed! Tracking: ${order['tracking_number']}'), backgroundColor: accentColor),
        );
        auth.clearCart();
        Navigator.pushReplacementNamed(context, '/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _checkoutWithFlutterwave() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: auth.cartItems.isEmpty
          ? Center(child: Text('Cart is empty', style: GoogleFonts.poppins(fontSize: 18, color: textColor)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: auth.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = auth.cartItems[index];
                      return ListTile(
                        title: Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.restaurantName ?? 'Unknown Restaurant',
                                style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                            Text('\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                                style: GoogleFonts.poppins()),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => auth.removeFromCart(item.name),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('\$${auth.cartTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isProcessing
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _checkoutWithStripe(auth),
                                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                                  child: Text('Checkout with Stripe', style: GoogleFonts.poppins(fontSize: 16)),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _checkoutWithFlutterwave,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: accentColor,
                                  ),
                                  child: Text('Checkout with Flutterwave',
                                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
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
}