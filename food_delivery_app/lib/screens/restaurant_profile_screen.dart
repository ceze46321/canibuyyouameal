import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'checkout_screen.dart';

class RestaurantProfileScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantProfileScreen({super.key, required this.restaurant});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  List<Map<String, dynamic>> cart = [];
  final List<Map<String, dynamic>> menu = [
    {'id': 1, 'name': 'Jollof Rice', 'price': 4.99, 'description': 'Spicy Nigerian rice dish'},
    {'id': 2, 'name': 'Egusi Soup', 'price': 6.99, 'description': 'Melon seed stew'},
  ];

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      cart.add({'id': item['id'], 'name': item['name'], 'price': item['price'], 'quantity': 1});
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} added to cart'), backgroundColor: accentColor));
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.restaurant['tags'] ?? {};
    return Scaffold(
      appBar: AppBar(
        title: Text(tags['name'] ?? 'Unnamed Restaurant', style: GoogleFonts.poppins()),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.network(
                widget.restaurant['image'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No Image Available')),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tags['name'] ?? 'Unnamed Restaurant',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: Lat ${widget.restaurant['lat']}, Lon ${widget.restaurant['lon']}',
                    style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7)),
                  ),
                  if (tags['address'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Address: ${tags['address']}', style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7))),
                  ],
                  const SizedBox(height: 16),
                  Text('Menu', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final item = menu[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['description'], style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                              Text('\$${item['price']}', style: GoogleFonts.poppins(color: secondaryColor)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add, color: primaryColor),
                            onPressed: () => _addToCart(item),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart))),
              backgroundColor: secondaryColor,
              child: const Icon(Icons.shopping_cart),
            )
          : null,
    );
  }
}