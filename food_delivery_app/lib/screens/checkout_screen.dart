import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../main.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService apiService = ApiService();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isRush = false;
  bool _isLoading = false;
  String? _paymentIntentId;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY'; // Replace with your key
  }

  Future<void> _initPayment(double total) async {
    try {
      final response = await http.post(
        Uri.parse('$ApiService.baseUrl/create-payment-intent'),
        headers: apiService.headers, // Changed from _headers to headers
        body: json.encode({'amount': (total * 100).toInt()}),
      );
      final data = json.decode(response.body);
      _paymentIntentId = data['id'];
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['client_secret'],
          merchantDisplayName: 'Chiw Express',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red));
      rethrow;
    }
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an address'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      double total = widget.cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
      await _initPayment(total);
      final order = await apiService.placeOrder(widget.cart, _addressController.text, notes: _notesController.text, isRush: _isRush);
      await http.post(
        Uri.parse('$ApiService.baseUrl/send-confirmation-email'),
        headers: apiService.headers, // Changed from _headers to headers
        body: json.encode({'order_id': order['id']}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully'), backgroundColor: accentColor));
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushNamed(context, '/orders');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
    return Scaffold(
      appBar: AppBar(title: Text('Checkout', style: GoogleFonts.poppins()), backgroundColor: primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Summary', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.cart.length,
                      itemBuilder: (context, index) {
                        final item = widget.cart[index];
                        return ListTile(
                          title: Text(item['name'], style: GoogleFonts.poppins()),
                          subtitle: Text('Qty: ${item['quantity']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                          trailing: Text('\$${item['price'] * item['quantity']}', style: GoogleFonts.poppins(color: secondaryColor)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(value: _isRush, onChanged: (value) => setState(() => _isRush = value!), activeColor: primaryColor),
                        Text('Rush Delivery', style: GoogleFonts.poppins()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('\$${total.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 18, color: secondaryColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text('Pay \$${total.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}