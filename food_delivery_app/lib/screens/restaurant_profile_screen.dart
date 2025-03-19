import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor, secondaryColor;
import 'checkout_screen.dart';

class RestaurantProfileScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantProfileScreen({super.key, required this.restaurant});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final List<Map<String, dynamic>> menu = [
    {'id': 1, 'name': 'Jollof Rice', 'price': 4.99, 'description': 'Spicy Nigerian rice dish'},
    {'id': 2, 'name': 'Egusi Soup', 'price': 6.99, 'description': 'Melon seed stew'},
  ];

  void _addToCart(AuthProvider auth, Map<String, dynamic> item) {
    final restaurantName = widget.restaurant['tags']?['name'] ?? 'Unnamed Restaurant';
    auth.addToCart(item['name'], item['price'] as double, restaurantName: restaurantName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart'), backgroundColor: accentColor),
    );
  }

  void _updateQuantity(AuthProvider auth, String itemName, double itemPrice, int change) {
    final restaurantName = widget.restaurant['tags']?['name'] ?? 'Unnamed Restaurant';
    auth.updateCartItemQuantity(itemName, itemPrice, change, restaurantName: restaurantName);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tags = widget.restaurant['tags'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(tags['name'] ?? 'Unnamed Restaurant', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu refresh coming soon!'), backgroundColor: accentColor),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                widget.restaurant['image'] ?? 'https://via.placeholder.com/300',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No Image Available', style: TextStyle(color: Colors.grey))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tags['name'] ?? 'Unnamed Restaurant',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: primaryColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Location: Lat ${widget.restaurant['lat'] ?? 'N/A'}, Lon ${widget.restaurant['lon'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  if (tags['address'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home, color: primaryColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Address: ${tags['address']}',
                          style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menu',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      if (auth.cartItems.isNotEmpty)
                        Text(
                          'Cart: ${auth.cartTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontSize: 14, color: accentColor),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final item = menu[index];
                      final cartItemCount = auth.cartItems
                          .where((cartItem) => cartItem.name == item['name'])
                          .fold(0, (sum, item) => sum + item.quantity);
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    Text(
                                      item['description'],
                                      style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                                    ),
                                    Text(
                                      '\$${item['price']}',
                                      style: GoogleFonts.poppins(fontSize: 14, color: secondaryColor),
                                    ),
                                  ],
                                ),
                              ),
                              cartItemCount == 0
                                  ? IconButton(
                                      icon: const Icon(Icons.add_circle, color: primaryColor),
                                      onPressed: () => _addToCart(auth, item),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, color: primaryColor),
                                          onPressed: () => _updateQuantity(auth, item['name'], item['price'] as double, -1),
                                        ),
                                        Text(
                                          '$cartItemCount',
                                          style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: primaryColor),
                                          onPressed: () => _updateQuantity(auth, item['name'], item['price'] as double, 1),
                                        ),
                                      ],
                                    ),
                            ],
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
      floatingActionButton: auth.cartItems.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
              backgroundColor: secondaryColor,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: accentColor,
                      child: Text(
                        '${auth.cartItems.length}',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}