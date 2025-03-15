import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main.dart';

class DasherScreen extends StatefulWidget {
  const DasherScreen({super.key});

  @override
  State<DasherScreen> createState() => _DasherScreenState();
}

class _DasherScreenState extends State<DasherScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> deliveries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    try {
      // Assuming an endpoint like /dasher/deliveries exists
      final response = await apiService.getOrders(); // Placeholder; replace with dasher-specific API
      setState(() {
        deliveries = response.where((order) => order['status'] == 'in_transit').toList(); // Example filter
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
        title: Text('Dasher Dashboard', style: GoogleFonts.poppins()),
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
                    'Assigned Deliveries',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: deliveries.isEmpty
                        ? const Center(child: Text('No deliveries assigned'))
                        : ListView.builder(
                            itemCount: deliveries.length,
                            itemBuilder: (context, index) {
                              final delivery = deliveries[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text('Order #${delivery['id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Address: ${delivery['address']}', style: GoogleFonts.poppins()),
                                      Text('Status: ${delivery['status']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {}, // Add logic to update status (e.g., "Delivered")
                                    child: const Text('Mark Delivered'),
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