import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List<dynamic> restaurants = [];
  bool isLoading = true;
  int currentPage = 1;
  int perPage = 10;
  int totalPages = 1;
  String searchQuery = '';
  String filterState = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants({int page = 1}) async {
    setState(() {
      isLoading = true;
      currentPage = page;
    });

    try {
      final uri = Uri.parse('https://plus.apexjets.org/api/restaurants').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          'sort': '-id',
          if (filterState.isNotEmpty) 'state': filterState,
          if (searchQuery.isNotEmpty) 'q': searchQuery,
        },
      );

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        // Add auth token if required: 'Authorization': 'Bearer ${auth.token}',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug: Log the full response
        setState(() {
          restaurants = data['data'] ?? [];
          totalPages = data['meta'] != null && data['meta']['last_page'] != null
              ? data['meta']['last_page']
              : (restaurants.length < perPage ? currentPage : currentPage + 1); // Fallback if meta is missing
          isLoading = false;
        });
        print('Current Page: $currentPage, Total Pages: $totalPages'); // Debug: Check pagination values
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
    });
    fetchRestaurants(page: 1);
  }

  void _onStateFilterChanged() {
    setState(() {
      filterState = _stateController.text;
    });
    fetchRestaurants(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurants', style: GoogleFonts.poppins()),
        backgroundColor: primaryColor,
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
                    labelText: 'Search Restaurants',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _onSearchChanged,
                    ),
                  ),
                  onSubmitted: (_) => _onSearchChanged(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'Filter by State',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _onStateFilterChanged,
                    ),
                  ),
                  onSubmitted: (_) => _onStateFilterChanged(),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : restaurants.isEmpty
                    ? const Center(child: Text('No restaurants found', style: TextStyle(fontSize: 18)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: restaurant['image'] != null && restaurant['image'].isNotEmpty
                                      ? Image.network(
                                          restaurant['image'],
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 120,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error, size: 50, color: Colors.red),
                                          ),
                                        )
                                      : Container(
                                          height: 120,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant['name'] ?? 'Unnamed Restaurant',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        restaurant['address'] ?? 'No address',
                                        style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${restaurant['state'] ?? 'No state'}, ${restaurant['country'] ?? 'No country'}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
                                      ),
                                      Text(
                                        'Category: ${restaurant['category'] ?? 'Unknown'}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 1
                        ? () {
                            print('Previous pressed, fetching page ${currentPage - 1}'); // Debug
                            fetchRestaurants(page: currentPage - 1);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Previous'),
                  ),
                  Text('Page $currentPage of $totalPages', style: GoogleFonts.poppins()),
                  ElevatedButton(
                    onPressed: currentPage < totalPages
                        ? () {
                            print('Next pressed, fetching page ${currentPage + 1}'); // Debug
                            fetchRestaurants(page: currentPage + 1);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}