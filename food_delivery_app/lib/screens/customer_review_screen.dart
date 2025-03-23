import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;

class CustomerReviewScreen extends StatefulWidget {
  const CustomerReviewScreen({super.key});

  @override
  State<CustomerReviewScreen> createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
  int _selectedIndex = 0; // Default to Home for consistency, adjust as needed

  @override
  void initState() {
    super.initState();
    // Fetch reviews when the screen loads
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoadingReviews && authProvider.reviews.isEmpty) {
      authProvider.fetchCustomerReviews();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/orders',
      3: '/profile',
      4: '/restaurant-owner',
      5: '/dashers',
    };
    if (routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Reviews',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor, // Warm Coral from main.dart
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: authProvider.isLoadingReviews
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            : authProvider.reviews.isEmpty
                ? Center(
                    child: Text(
                      'No reviews available yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 0.8, // Slightly taller cards
                    ),
                    itemCount: authProvider.reviews.length,
                    itemBuilder: (context, index) {
                      final review = authProvider.reviews[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  review.rating,
                                  (i) => const Icon(Icons.star, color: Colors.amber, size: 18),
                                ),
                                mainAxisAlignment: MainAxisAlignment.start,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                review.customerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  review.comment ?? 'No comment provided',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reviewed: ${review.createdAt.toLocal().toString().split('.')[0]}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Dasher'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor, // DoorDash red from main.dart
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        backgroundColor: Colors.white,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          authProvider.fetchCustomerReviews(); // Refresh reviews
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refreshing reviews...', style: GoogleFonts.poppins()),
              backgroundColor: accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh Reviews',
      ),
    );
  }
}