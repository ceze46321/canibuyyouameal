import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../main.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _locationController = TextEditingController();
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      orders = await apiService.getOrders();
      setState(() => isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateLocation() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a location'), backgroundColor: Colors.red));
      return;
    }
    setState(() => isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile(auth.name!, auth.email!, restaurantDetails: {'delivery_location': _locationController.text});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated'), backgroundColor: accentColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logistics', style: GoogleFonts.poppins()),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Location Section
                  Text(
                    'Delivery Location',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Enter your delivery address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: primaryColor),
                        onPressed: _updateLocation,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Orders Section
                  Text(
                    'Your Orders',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(child: Text('No orders yet'))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text('Order #${order['id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total: \$${order['total']}', style: GoogleFonts.poppins()),
                                      Text('Status: ${order['status']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                      Text('Address: ${order['address']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                    ],
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