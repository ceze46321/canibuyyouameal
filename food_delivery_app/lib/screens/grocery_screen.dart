import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';
import '../models/product_model.dart';
import 'restaurant_screen.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 2;
  List<Map<String, dynamic>> cart = [];
  String searchQuery = '';
  String selectedLocation = 'All';

  @override
  void initState() {
    super.initState();
    stripe.Stripe.publishableKey = 'pk_test_51R3VqwFo5xO98pwdjgCiM3rXeI9My0RcZHHEZPJXipbsjZ80ydOnprPsBQZQ9GEmY6aTARgWb7tWxofFLTGqINfq00seIuXSDB';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchGroceryProducts();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Product> _filterGroceries(List<Product> groceries) {
    return groceries.where((product) {
      final matchesName = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesName;
    }).toList();
  }

  void _addToCart(Product product) {
    setState(() {
      cart.add({
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'image': product.imageUrl,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: accentColor),
    );
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Payment Method', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Stripe', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
            ListTile(
              title: Text('Flutterwave', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, 'flutterwave'),
            ),
          ],
        ),
      ),
    );

    if (paymentMethod == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final groceryItems = cart.map((item) => ({
            'name': item['name'],
            'quantity': item['quantity'],
            'price': item['price'],
            'image': item['image'],
          })).toList();
      final newGrocery = await authProvider.createGrocery(groceryItems);
      final groceryId = newGrocery['id'].toString();
      final response = await authProvider.initiateCheckout(groceryId, paymentMethod: paymentMethod);

      if (paymentMethod == 'stripe') {
        final clientSecret = response['client_secret'];
        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Chiw Express',
          ),
        );
        await stripe.Stripe.instance.presentPaymentSheet();
        setState(() => cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!'), backgroundColor: accentColor),
        );
      } else if (paymentMethod == 'flutterwave') {
        final paymentLink = response['payment_link'];
        if (await canLaunchUrl(Uri.parse(paymentLink))) {
          await launchUrl(Uri.parse(paymentLink), mode: LaunchMode.externalApplication);
          // Note: Cart clearing depends on payment confirmation (e.g., via webhook or manual check)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment initiated! Complete in browser.'), backgroundColor: accentColor),
          );
        } else {
          throw 'Could not launch $paymentLink';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 2 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
    }
  }

  void _showImageZoomDialog(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 3.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 100, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final groceries = authProvider.groceryProducts;
        final filteredGroceries = _filterGroceries(groceries);

        return Scaffold(
          appBar: AppBar(
            title: Text('Groceries', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: primaryColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: authProvider.isLoggedIn ? () => authProvider.fetchGroceryProducts() : null,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor.withOpacity(0.1), Colors.white],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.search, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedLocation,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['All'].map((location) {
                          return DropdownMenuItem(value: location, child: Text(location, style: GoogleFonts.poppins()));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedLocation = value!);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: !authProvider.isLoggedIn
                      ? const Center(child: Text('Please log in to view groceries'))
                      : groceries.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: primaryColor))
                          : filteredGroceries.isEmpty
                              ? Center(
                                  child: Text(
                                    'No groceries found',
                                    style: GoogleFonts.poppins(fontSize: 20, color: textColor.withOpacity(0.7)),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: filteredGroceries.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredGroceries[index];
                                    return _buildGroceryItem(product);
                                  },
                                ),
                ),
                if (cart.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cart: ${cart.length} items',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Checkout', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
              BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
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
      },
    );
  }

  Widget _buildGroceryItem(Product product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageZoomDialog(context, product.imageUrl),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: accentColor.withOpacity(0.3),
                          child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                        ),
                      )
                    : Container(
                        height: 150,
                        color: accentColor.withOpacity(0.3),
                        child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${product.price} (Qty: ${product.quantity})',
                  style: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: primaryColor),
                    onPressed: () => _addToCart(product),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}