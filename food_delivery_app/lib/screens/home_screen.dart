import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.name ?? 'Foodie';
    final userRole = auth.role ?? 'Visitor';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Welcome, $userName!',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://i.imgur.com/XNoTAaX.jpeg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/profile'), // Link to ProfileScreen
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chiw Express: Your Local Food Adventure',
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover the taste of Nigeria with fast, reliable delivery.',
                      style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your role: $userRole',
                      style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureCard(
                      icon: Icons.local_dining,
                      title: 'Local Flavors',
                      description: 'Support local restaurants with authentic dishes.',
                    ),
                    _buildFeatureCard(
                      icon: Icons.flash_on,
                      title: 'Lightning Fast',
                      description: 'Get your food delivered in record time.',
                    ),
                    _buildFeatureCard(
                      icon: Icons.verified,
                      title: 'Trusted Service',
                      description: 'Reliable delivery to your doorstep.',
                    ),
                    const SizedBox(height: 24),

                    // Featured Restaurants Section
                    Text(
                      'Featured Restaurants',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildRestaurantCard('Taste of Lagos', 'https://via.placeholder.com/150', 'Lagos, NG'),
                          _buildRestaurantCard('Spicy Kitchen', 'https://via.placeholder.com/150', 'Abuja, NG'),
                          _buildRestaurantCard('Food Haven', 'https://via.placeholder.com/150', 'Port Harcourt, NG'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildActionButton(context, 'Order Food', Icons.fastfood, '/restaurants'),
                        _buildActionButton(context, 'Track Order', Icons.local_shipping, '/orders'),
                        if (userRole == 'merchant')
                          _buildActionButton(context, 'Manage Restaurants', Icons.store, '/restaurant-owners'),
                        if (userRole == 'dasher')
                          _buildActionButton(context, 'Deliver Orders', Icons.directions_bike, '/dashers'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Explore More',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFooterButton(context, 'Restaurants', '/restaurants'),
                        _buildFooterButton(context, 'Orders', '/orders'),
                        _buildFooterButton(context, 'Logistics', '/logistics'),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String description}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  Text(description, style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: primaryColor)),
    );
  }

  Widget _buildRestaurantCard(String name, String imageUrl, String location) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl, height: 100, width: 150, fit: BoxFit.cover),
            const SizedBox(height: 8),
            Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(location, style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, String route) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: primaryColor,
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}