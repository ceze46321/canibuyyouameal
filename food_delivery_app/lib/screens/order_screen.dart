import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor, secondaryColor;
import 'package:flutter_animate/flutter_animate.dart';

class OrderScreen extends StatefulWidget {
  final String? orderId;
  final String? initialStatus;

  const OrderScreen({super.key, this.orderId, this.initialStatus});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool isLoading = true;
  int _selectedIndex = 2;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fetchOrders();
    if (widget.initialStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialStatus == 'completed'
                  ? 'Payment successful! Your order is on the way!'
                  : widget.initialStatus == 'cancelled'
                      ? 'Payment cancelled. Try again?'
                      : 'Payment failed. Please retry.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: widget.initialStatus == 'completed' ? accentColor : Colors.redAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fetchedOrders = await auth.getOrders();
      if (mounted) {
        setState(() {
          orders = fetchedOrders;
          isLoading = false;
          if (widget.orderId != null) {
            final matchedOrder = orders.firstWhere(
              (order) => order['id'].toString() == widget.orderId,
              orElse: () => null,
            );
            if (matchedOrder != null) {
              print('Matched order: ${matchedOrder['id']}');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: Text('Are you sure you want to cancel this order?', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Yes', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.cancelOrder(orderId);
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order cancelled successfully'), backgroundColor: accentColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
        );
      }
    }
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
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/restaurant-owner');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.7),
                  secondaryColor.withOpacity(0.3),
                  const Color(0xFFF5F5F5),
                ],
              ),
            ),
            child: CustomPaint(painter: WavePainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Orders',
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                        onPressed: isLoading ? null : _fetchOrders,
                        tooltip: 'Refresh Orders',
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms),
                Expanded(
                  child: isLoading
                      ? Center(child: SpinKitPouringHourGlassRefined(color: primaryColor, size: 60))
                      : orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fastfood, size: 100, color: textColor.withOpacity(0.2)),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No orders yet',
                                    style: GoogleFonts.poppins(fontSize: 20, color: textColor.withOpacity(0.7)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Order some delicious food now!',
                                    style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.5)),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 800.ms),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchOrders,
                              color: primaryColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: orders.length,
                                itemBuilder: (context, index) {
                                  final order = orders[index];
                                  final isHighlighted = widget.orderId != null && order['id'].toString() == widget.orderId;
                                  return _buildOrderCard(order, isHighlighted);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ).animate().slideY(begin: 1.0, end: 0.0, duration: 500.ms),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isHighlighted) {
    return Animate(
      effects: [FadeEffect(duration: const Duration(milliseconds: 600)), SlideEffect(begin: const Offset(0, 0.2), end: Offset.zero)],
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(trackingNumber: order['tracking_number'] ?? ''))),
        child: Card(
          elevation: isHighlighted ? 10 : 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.white,
          shadowColor: isHighlighted ? primaryColor.withOpacity(0.4) : primaryColor.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fastfood, size: 24, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Order #${order['id']}',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['status']),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _getStatusColor(order['status']).withOpacity(0.3), blurRadius: 6)],
                      ),
                      child: Text(
                        order['status'],
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${order['total'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
                    Text(
                      'Items: ${order['items']?.length ?? 'N/A'}',
                      style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tracking: ${order['tracking_number'] ?? 'Pending'}',
                  style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order['status'] == 'pending')
                      ElevatedButton.icon(
                        onPressed: () => _cancelOrder(order['id'].toString()),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 2,
                        ),
                      ).animate().scale(duration: 200.ms),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(trackingNumber: order['tracking_number'] ?? ''))),
                      icon: const Icon(Icons.track_changes, size: 18),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 2,
                      ),
                    ).animate().scale(duration: 200.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return secondaryColor;
      case 'in_transit':
        return Colors.blueAccent;
      case 'delivered':
        return accentColor;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey.shade400;
    }
  }
}

class TrackingScreen extends StatefulWidget {
  final String trackingNumber;
  const TrackingScreen({super.key, required this.trackingNumber});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? trackingData;
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    if (widget.trackingNumber.isNotEmpty) _fetchTracking();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTracking() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      trackingData = await auth.getOrderTracking(widget.trackingNumber);
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.7),
                  secondaryColor.withOpacity(0.3),
                  const Color(0xFFF5F5F5),
                ],
              ),
            ),
            child: CustomPaint(painter: WavePainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Track Order #${widget.trackingNumber}',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms),
                Expanded(
                  child: isLoading
                      ? Center(child: SpinKitPouringHourGlassRefined(color: primaryColor, size: 60))
                      : trackingData == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_shipping, size: 100, color: textColor.withOpacity(0.2)),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Tracking not available yet',
                                    style: GoogleFonts.poppins(fontSize: 20, color: textColor.withOpacity(0.7)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Check back soon!',
                                    style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.5)),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 800.ms),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                shadowColor: primaryColor.withOpacity(0.3),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.local_shipping, size: 28, color: primaryColor),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Tracking Details',
                                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _buildTrackingTimeline(),
                                      const SizedBox(height: 24),
                                      Container(
                                        height: 250,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [secondaryColor.withOpacity(0.4), Colors.grey[200]!],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8)],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(Icons.map, size: 80, color: textColor.withOpacity(0.3)),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Map Coming Soon',
                                                  style: GoogleFonts.poppins(fontSize: 18, color: textColor.withOpacity(0.7)),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Stay tuned for real-time tracking!',
                                                  style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn(duration: 800.ms),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final steps = [
      {'icon': Icons.local_shipping, 'title': 'Status', 'subtitle': trackingData!['status'], 'isActive': true},
      {
        'icon': Icons.location_on,
        'title': 'Location',
        'subtitle': 'Lat ${trackingData!['lat'] ?? 'N/A'}, Lon ${trackingData!['lon'] ?? 'N/A'}',
        'isActive': trackingData!['lat'] != null
      },
      {
        'icon': Icons.update,
        'title': 'Last Updated',
        'subtitle': trackingData!['updated_at'] ?? 'N/A',
        'isActive': trackingData!['updated_at'] != null
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Animate(
          effects: [FadeEffect(delay: Duration(milliseconds: index * 200)), SlideEffect(begin: const Offset(0, 0.2), end: Offset.zero)],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step['isActive'] ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        border: Border.all(color: step['isActive'] ? primaryColor : Colors.grey, width: 2),
                      ),
                      child: Icon(step['icon'], color: step['isActive'] ? primaryColor : textColor.withOpacity(0.3), size: 24),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: step['isActive'] ? primaryColor.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['subtitle'],
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.65, size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.85, size.width, size.height * 0.75);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}