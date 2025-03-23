import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:uni_links/uni_links.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';
import 'restaurant_screen.dart';
import 'create_grocery_product_screen.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 2;
  List<Map<String, dynamic>> cart = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _allGroceries = [];
  List<Map<String, dynamic>> _filteredGroceries = [];
  StreamSubscription? _sub;
  bool _isLoading = true;

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    stripe.Stripe.publishableKey = 'pk_test_51R3VqwFo5xO98pwdjgCiM3rXeI9My0RcZHHEZPJXipbsjZ80ydOnprPsBQZQ9GEmY6aTARgWb7tWxofFLTGqINfq00seIuXSDB';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fetchGroceries();
    _initDeepLinkListener(); // Define this method below
    _searchController.addListener(_onFilterChanged);
    _locationController.addListener(_onFilterChanged);
  }

  Future<void> _fetchGroceries() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final groceries = await authProvider.fetchGroceryProducts();
      if (mounted) {
        setState(() {
          _allGroceries = List<Map<String, dynamic>>.from(groceries); // Ensure type safety
          _filteredGroceries = _flattenAndFilterGroceries(_allGroceries);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching groceries: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initDeepLinkListener() async {
    // Handle initial deep link
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      debugPrint('Initial deep link: $initialLink');
      _handleDeepLink(initialLink);
    }

    // Listen for deep links during runtime
    _sub = linkStream.listen((String? link) {
      if (link != null) {
        debugPrint('Received deep link: $link');
        _handleDeepLink(link);
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deep link error: $err'), backgroundColor: Colors.redAccent),
      );
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final status = uri.queryParameters['status'];
    if (status == 'completed') {
      setState(() => cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!'), backgroundColor: doorDashRed),
      );
    }
  }

  Future<void> _onFilterChanged() async {
    final query = _searchController.text.trim();
    final location = _locationController.text.trim();

    if (query.isEmpty && location.isEmpty) {
      setState(() {
        _filteredGroceries = _flattenAndFilterGroceries(_allGroceries);
      });
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final filtered = await authProvider.getFilteredGroceries(query, location);
      if (mounted) {
        setState(() {
          _filteredGroceries = _flattenAndFilterGroceries(List<Map<String, dynamic>>.from(filtered)); // Type cast
        });
      }
    } catch (e) {
      debugPrint('Error filtering groceries: $e');
      _filterGroceriesClientSide(query, location);
    }
  }

  List<Map<String, dynamic>> _flattenAndFilterGroceries(List<Map<String, dynamic>> groceries) {
    final allItems = groceries.expand((grocery) {
      final items = grocery['items'] as List<dynamic>? ?? [];
      return items.map((item) => ({
            'id': grocery['id']?.toString() ?? 'unknown',
            'name': item['name']?.toString() ?? 'Unnamed',
            'stock_quantity': item['quantity'] ?? 1,
            'price': (item['price'] as num?)?.toDouble() ?? 0.0,
            'image': item['image']?.toString(),
            'location': grocery['location']?.toString() ?? '',
          }));
    }).toList();

    final query = _searchController.text.toLowerCase().trim();
    final location = _locationController.text.toLowerCase().trim();

    return allItems.where((item) {
      final matchesName = (item['name'] ?? '').toLowerCase().contains(query);
      final matchesLocation = location.isEmpty || (item['location'] ?? '').toLowerCase().contains(location);
      return matchesName && matchesLocation;
    }).toList();
  }

  void _filterGroceriesClientSide(String query, String location) {
    setState(() {
      _filteredGroceries = _allGroceries.expand((grocery) {
        final items = grocery['items'] as List<dynamic>? ?? [];
        return items.map((item) => ({
              'id': grocery['id']?.toString() ?? 'unknown',
              'name': item['name']?.toString() ?? 'Unnamed',
              'stock_quantity': item['quantity'] ?? 1,
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              'image': item['image']?.toString(),
              'location': grocery['location']?.toString() ?? '',
            }));
      }).where((item) {
        final matchesName = (item['name'] ?? '').toLowerCase().contains(query.toLowerCase());
        final matchesLocation = location.isEmpty || (item['location'] ?? '').toLowerCase().contains(location.toLowerCase());
        return matchesName && matchesLocation;
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingItemIndex = cart.indexWhere((cartItem) => cartItem['id'] == item['id']);
      if (existingItemIndex != -1) {
        cart[existingItemIndex]['ordered_quantity'] = (cart[existingItemIndex]['ordered_quantity'] ?? 0) + 1;
      } else {
        cart.add({
          'id': item['id'],
          'name': item['name'],
          'stock_quantity': item['stock_quantity'],
          'ordered_quantity': 1,
          'price': item['price'],
          'image': item['image'],
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart!'), backgroundColor: doorDashRed),
    );
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      final existingItemIndex = cart.indexWhere((cartItem) => cartItem['id'] == item['id']);
      if (existingItemIndex != -1) {
        final currentQuantity = cart[existingItemIndex]['ordered_quantity'] as int;
        if (currentQuantity > 1) {
          cart[existingItemIndex]['ordered_quantity'] = currentQuantity - 1;
        } else {
          cart.removeAt(existingItemIndex);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} removed from cart!'), backgroundColor: doorDashRed),
        );
      }
    });
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to proceed'), backgroundColor: Colors.redAccent),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: doorDashRed,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Text(
                  'Choose Payment Method',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption('Stripe', 'stripe'),
              const SizedBox(height: 12),
              _buildPaymentOption('Flutterwave', 'flutterwave'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(color: doorDashGrey, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );

    if (paymentMethod == null) return;

    try {
      final groceryItems = cart.map((item) => ({
            'name': item['name'],
            'quantity': item['stock_quantity'],
            'ordered_quantity': item['ordered_quantity'],
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
            merchantDisplayName: 'CanIbuyYouAMeal Express',
          ),
        );
        await stripe.Stripe.instance.presentPaymentSheet();
        setState(() => cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!'), backgroundColor: doorDashRed),
        );
      } else if (paymentMethod == 'flutterwave') {
        final paymentLink = response['payment_link'];
        if (await canLaunchUrl(Uri.parse(paymentLink))) {
          await launchUrl(Uri.parse(paymentLink), mode: LaunchMode.externalApplication);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment initiated! Complete in browser.'), backgroundColor: doorDashRed),
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

  Widget _buildPaymentOption(String title, String value) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: doorDashGrey.withOpacity(0.2)),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, color: textColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/groceries',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 2 && routes.containsKey(index)) {
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
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
  void dispose() {
    _sub?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: doorDashLightGrey,
          appBar: AppBar(
            title: Text('Groceries', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            backgroundColor: doorDashRed,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchGroceries,
              ),
              if (authProvider.isRestaurantOwner)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroceryProductScreen())),
                  tooltip: 'Create Product',
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: GoogleFonts.poppins(color: doorDashGrey),
                        prefixIcon: const Icon(Icons.search, color: doorDashRed),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: doorDashRed),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Filter by location...',
                        hintStyle: GoogleFonts.poppins(color: doorDashGrey),
                        prefixIcon: const Icon(Icons.location_on, color: doorDashRed),
                        suffixIcon: _locationController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: doorDashRed),
                                onPressed: () => _locationController.clear(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: doorDashRed))
                    : !authProvider.isLoggedIn
                        ? Center(child: Text('Please log in to view groceries', style: GoogleFonts.poppins(color: doorDashGrey)))
                        : _allGroceries.isEmpty
                            ? Center(
                                child: Text(
                                  'No groceries available',
                                  style: GoogleFonts.poppins(fontSize: 20, color: doorDashGrey),
                                ),
                              )
                            : _filteredGroceries.isEmpty
                                ? Center(
                                    child: Text(
                                      'No groceries match your search',
                                      style: GoogleFonts.poppins(fontSize: 20, color: doorDashGrey),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.7,
                                    ),
                                    itemCount: _filteredGroceries.length,
                                    itemBuilder: (context, index) {
                                      final product = _filteredGroceries[index];
                                      return _buildGroceryItem(product);
                                    },
                                  ),
              ),
              if (cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Cart',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      ...cart.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['name']} x ${item['ordered_quantity']}',
                                    style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                                  ),
                                ),
                                Text(
                                  '₦${(item['ordered_quantity'] * item['price']).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: doorDashRed),
                                  onPressed: () => _removeFromCart(item),
                                ),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ₦${cart.fold(0.0, (sum, item) => sum + (item['ordered_quantity'] * item['price'])).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          ElevatedButton(
                            onPressed: _checkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: doorDashRed,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Checkout', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/my-groceries'),
                      child: Text(
                        'View My Orders',
                        style: GoogleFonts.poppins(color: doorDashRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroceryProductScreen())),
                      child: Text(
                        'Add New Order',
                        style: GoogleFonts.poppins(color: doorDashRed, fontWeight: FontWeight.w600),
                      ),
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
              BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: doorDashRed,
            unselectedItemColor: doorDashGrey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(),
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  Widget _buildGroceryItem(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageZoomDialog(context, product['image']),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product['image'] != null
                    ? Image.network(
                        product['image']!,
                        fit: BoxFit.cover,
                        height: 150,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                        ),
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unnamed',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${(product['price'] as num?)?.toStringAsFixed(2) ?? 'N/A'} • Stock: ${product['stock_quantity']?.toString() ?? 'N/A'}',
                  style: GoogleFonts.poppins(color: doorDashGrey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, color: doorDashRed, size: 28),
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