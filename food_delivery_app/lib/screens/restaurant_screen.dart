import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'restaurant_profile_screen.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late Future<List<dynamic>> _futureRestaurants;
  List<dynamic> _allRestaurants = [];
  List<dynamic> _filteredRestaurants = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 6;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _fetchRestaurants();
    _searchController.addListener(_filterRestaurants);
    _locationController.addListener(_filterRestaurants);
  }

  Future<List<dynamic>> _fetchRestaurants() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final restaurants = await authProvider.getRestaurants();
      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _filteredRestaurants = restaurants;
        });
      }
      return restaurants;
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
      return [];
    }
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase().trim();
    final location = _locationController.text.toLowerCase().trim();

    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        final name = (restaurant['name'] ?? '').toString().toLowerCase();
        final address = (restaurant['address'] ?? '').toString().toLowerCase();
        return name.contains(query) && (location.isEmpty || address.contains(location));
      }).toList();
      _currentPage = 1;
    });
  }

  List<dynamic> _getPaginatedRestaurants() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredRestaurants.length);
    return _filteredRestaurants.sublist(startIndex, endIndex);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    final routes = {
      0: '/home',
      2: '/orders',
      3: '/profile',
      4: '/restaurant-owner',
    };

    if (index != 1 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurants', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => _futureRestaurants = _fetchRestaurants()),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) => IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  if (auth.cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
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
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error loading restaurants',
                style: GoogleFonts.poppins(color: textColor),
              ),
            );
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No restaurants available',
                style: GoogleFonts.poppins(color: textColor),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchRestaurants,
            child: Column(
              children: [
                _buildSearchFilters(),
                Expanded(child: _buildRestaurantGrid()),
                _buildPaginationControls(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
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
  }

  Widget _buildSearchFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: _inputDecoration('Search by name', Icons.search),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: _inputDecoration('Filter by location', Icons.location_on),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: primaryColor),
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: primaryColor),
              onPressed: () => _searchController.clear(),
            )
          : null,
    );
  }

  Widget _buildRestaurantGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _getPaginatedRestaurants().length,
      itemBuilder: (context, index) => _buildRestaurantCard(_getPaginatedRestaurants()[index]),
    );
  }

  Widget _buildRestaurantCard(dynamic restaurant) {
    final menus = (restaurant['menus'] as List<dynamic>?) ?? [];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RestaurantProfileScreen(restaurant: restaurant)),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantImage(restaurant['image']),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRestaurantInfo(restaurant),
                  const SizedBox(height: 8),
                  _buildMenuSection(menus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantImage(String? imageUrl) {
    debugPrint('Loading image from: $imageUrl');
    final validUrl = imageUrl != null && imageUrl.trim().isNotEmpty
        ? imageUrl
        : 'https://via.placeholder.com/300';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Image.network(
        validUrl,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 100,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image load error: $error');
          return Container(
            height: 100,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantInfo(dynamic restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant['name'] ?? 'Unnamed',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          restaurant['address'] ?? 'No address',
          style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMenuSection(List<dynamic> menus) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
          ),
          if (menus.isEmpty)
            Text(
              'No menu items',
              style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
            )
          else
            ...menus.take(2).map((item) => _buildMenuItem(item, auth, context)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(dynamic item, AuthProvider auth, BuildContext context) {
    final itemName = item['name'] ?? 'Unnamed';
    final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
    final restaurantName = item['restaurantName'] ?? 'Unknown';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        itemName,
        style: GoogleFonts.poppins(fontSize: 12, color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '\$${itemPrice.toStringAsFixed(2)}',
        style: GoogleFonts.poppins(fontSize: 12, color: accentColor),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_shopping_cart, color: accentColor),
        onPressed: () {
          auth.addToCart(itemName, itemPrice, restaurantName: restaurantName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$itemName added to cart'),
              backgroundColor: accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_filteredRestaurants.length / _itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentPage / $totalPages',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: primaryColor),
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}