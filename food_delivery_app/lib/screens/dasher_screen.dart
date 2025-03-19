import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart'; // Use AuthProvider instead of direct ApiService
import '../main.dart' show primaryColor, textColor, accentColor;

class DasherScreen extends StatefulWidget {
  const DasherScreen({super.key});

  @override
  State<DasherScreen> createState() => _DasherScreenState();
}

class _DasherScreenState extends State<DasherScreen> {
  List<dynamic> deliveries = [];
  bool isLoading = true;
  final Map<int, bool> _deliveryLoading = {}; // Track loading state per delivery

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.getDasherDeliveries(); // New method we'll add to AuthProvider
      if (mounted) {
        setState(() {
          deliveries = response.where((order) => order['status'] == 'in_transit').toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _markDelivered(int orderId) async {
    setState(() => _deliveryLoading[orderId] = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateDeliveryStatus(orderId, 'delivered'); // New method we'll add
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery marked as delivered'), backgroundColor: accentColor),
        );
        await _fetchDeliveries(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _deliveryLoading[orderId] = false);
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
                        ? Center(
                            child: Text(
                              'No deliveries assigned',
                              style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: deliveries.length,
                            itemBuilder: (context, index) {
                              final delivery = deliveries[index];
                              final orderId = delivery['id'] as int;
                              final isButtonLoading = _deliveryLoading[orderId] ?? false;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text('Order #$orderId', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Address: ${delivery['address'] ?? 'Unknown'}', style: GoogleFonts.poppins()),
                                      Text('Status: ${delivery['status']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                    ],
                                  ),
                                  trailing: isButtonLoading
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed: () => _markDelivered(orderId),
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