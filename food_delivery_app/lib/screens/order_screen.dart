import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService apiService = ApiService();
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

  Future<void> _cancelOrder(String orderId) async {
    try {
      await apiService.cancelOrder(orderId);
      _fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled'), backgroundColor: accentColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Orders', style: GoogleFonts.poppins()), backgroundColor: primaryColor),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                            Text('Tracking: ${order['tracking_number'] ?? 'Pending'}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (order['status'] == 'pending')
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _cancelOrder(order['id'].toString()),
                              ),
                            IconButton(
                              icon: const Icon(Icons.track_changes, color: primaryColor),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TrackingScreen(trackingNumber: order['tracking_number'] ?? '')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  final String trackingNumber;
  const TrackingScreen({super.key, required this.trackingNumber});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? trackingData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.trackingNumber.isNotEmpty) _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    try {
      trackingData = await apiService.getOrderTracking(widget.trackingNumber);
      setState(() => isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Order #${widget.trackingNumber}', style: GoogleFonts.poppins()), backgroundColor: primaryColor),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trackingData == null
              ? const Center(child: Text('Tracking not available yet'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${trackingData!['status']}', style: GoogleFonts.poppins(fontSize: 18)),
                      const SizedBox(height: 16),
                      Text('Location: Lat ${trackingData!['lat']}, Lon ${trackingData!['lon']}', style: GoogleFonts.poppins()),
                      const SizedBox(height: 16),
                      Text('Last Updated: ${trackingData!['updated_at']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                    ],
                  ),
                ),
    );
  }
}