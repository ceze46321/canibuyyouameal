import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> restaurants = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _fetchRestaurants();
    _animationController.forward();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fetchedRestaurants = await auth.getRestaurants();
      if (mounted) {
        setState(() {
          restaurants = fetchedRestaurants.take(10).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0: break;
      case 1: Navigator.pushReplacementNamed(context, '/restaurants'); break;
      case 2: Navigator.pushReplacementNamed(context, '/orders'); break;
      case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
      case 4: Navigator.pushReplacementNamed(context, '/restaurant-owner'); break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.name ?? 'Foodie';
    final userRole = auth.role ?? 'Visitor';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Welcome, $userName!',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(2, 2)),
                ]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://i.imgur.com/Qse69mz.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: primaryColor,
            elevation: 8,
            actions: [
              IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/dashboard')),
              IconButton(icon: const Icon(Icons.account_circle, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/profile')),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Can I get You A meal Store',
                      style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.2),
                    ),
                    Text(
                      'Your Nigerian Food Adventure Awaits',
                      style: GoogleFonts.poppins(fontSize: 18, color: textColor.withOpacity(0.8), fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Text('Role: $userRole', style: GoogleFonts.poppins(fontSize: 14, color: accentColor)),
                    const SizedBox(height: 30),

                    // Why Chiw Express Section
                    Text('Why Can I Buy You A Meal?', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    StaggeredGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildFeatureTile(Icons.local_dining, 'Authentic Taste', 'Savor Nigeria’s finest dishes.'),
                        _buildFeatureTile(Icons.flash_on, 'Fast Delivery', 'Food at your door in minutes.'),
                        _buildFeatureTile(Icons.verified, 'Trusted Service', 'Reliable every time.'),
                        _buildFeatureTile(Icons.people, 'Community', 'Support local vendors.'),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Featured Restaurants Section
                    Text('Featured Restaurants', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
                          : restaurants.isEmpty
                              ? Center(child: Text('No restaurants yet', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: restaurants.length,
                                  itemBuilder: (context, index) => _buildRestaurantCard(restaurants[index]),
                                ),
                    ),
                    const SizedBox(height: 30),

                    // Top Dishes Section
                    Text('Top Dishes', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildDishCard('Jollof Rice', 'https://i.imgur.com/8xN5K9P.jpg', 'Spicy & Savory'),
                          _buildDishCard('Pounded Yam', 'https://i.imgur.com/5zX7vQw.jpg', 'With Egusi Soup'),
                          _buildDishCard('Suya', 'https://i.imgur.com/Q3mK9tL.jpg', 'Grilled Perfection'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Testimonials Section
                    Text('What Our Users Say', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    _buildTestimonialCarousel(),
                    const SizedBox(height: 30),

                    // Quick Actions Section
                    Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildActionButton(context, 'Order Now', Icons.fastfood, () => Navigator.pushNamed(context, '/restaurants')),
                        _buildActionButton(context, 'Track Order', Icons.local_shipping, () => Navigator.pushNamed(context, '/orders')),
                        _buildActionButton(context, 'Groceries', Icons.local_grocery_store, () => Navigator.pushNamed(context, '/groceries')),
                        if (userRole == 'owner' || userRole == 'merchant')
                          _buildActionButton(context, 'Add Restaurant', Icons.store, () => Navigator.pushNamed(context, '/add-restaurant').then((_) => _fetchRestaurants())),
                        if (userRole == 'dasher')
                          _buildActionButton(context, 'Deliver', Icons.directions_bike, () => Navigator.pushNamed(context, '/dashers')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: primaryColor.withOpacity(0.05),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text('Explore More', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFooterButton(context, 'Restaurants', () => Navigator.pushNamed(context, '/restaurants')),
                      _buildFooterButton(context, 'Orders', () => Navigator.pushNamed(context, '/orders')),
                      _buildFooterButton(context, 'Logistics', () => Navigator.pushNamed(context, '/logistics')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
        elevation: 10,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/restaurants'),
        backgroundColor: accentColor,
        child: const Icon(Icons.fastfood, color: Colors.white),
        tooltip: 'Order Now',
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: primaryColor),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(description, style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(dynamic restaurant) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/restaurants'), // Could navigate to specific restaurant
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                restaurant['image'] ?? 'https://via.placeholder.com/150',
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 120, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    restaurant['address'] ?? 'Unknown',
                    style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishCard(String name, String imageUrl, String description) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(imageUrl, height: 100, width: 140, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(description, style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCarousel() {
    final testimonials = [
      {'name': 'Aisha', 'text': 'Fastest delivery I’ve ever experienced!', 'rating': 5},
      {'name': 'Tunde', 'text': 'The jollof rice is to die for.', 'rating': 4},
      {'name': 'Chioma', 'text': 'Love supporting local businesses.', 'rating': 5},
    ];
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          final testimonial = testimonials[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(testimonial['rating'] as int, (i) => const Icon(Icons.star, size: 16, color: Colors.amber)),
                ),
                const SizedBox(height: 8),
                Text('"${testimonial['text']}"', style: GoogleFonts.poppins(fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text('- ${testimonial['name']}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFooterButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
    );
  }
}