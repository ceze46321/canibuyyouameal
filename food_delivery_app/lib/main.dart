import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/mock_data.dart';
import 'models/cart.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Cart(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
        ).copyWith(
          secondary: Colors.yellow[700],
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    RestaurantScreen(),
    GroceryScreen(),
    DiscoverScreen(),
    OrderScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Delivery'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (Provider.of<Cart>(context).items.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${Provider.of<Cart>(context).items.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen()),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Grocery'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class RestaurantScreen extends StatelessWidget {
  final List<List<Color>> gradients = [
    [Colors.teal.shade300, Colors.teal.shade700],
    [Colors.orange.shade300, Colors.orange.shade700],
    [Colors.purple.shade300, Colors.purple.shade700],
    [Colors.green.shade300, Colors.green.shade700],
    [Colors.red.shade300, Colors.red.shade700],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: mockRestaurants.map((restaurant) {
            int gradientIndex = mockRestaurants.indexOf(restaurant) % gradients.length;
            return StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: restaurant['id'].isOdd ? 1.5 : 1.2,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(restaurant: restaurant),
                  ),
                ),
                child: GFCard(
                  gradient: LinearGradient(
                    colors: gradients[gradientIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  elevation: 8, // Replaced boxShadow
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          restaurant['image'],
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Explore Menu',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.yellow[200],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(duration: 600.ms, delay: (100 * gradientIndex).ms)
                    .scale(
                      begin: Offset(0.8, 0.8),
                      end: Offset(1, 1),
                      duration: 400.ms,
                    ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  MenuScreen({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    var menu = restaurant['menu'] as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant['name']),
        backgroundColor: Colors.teal,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: menu.length,
        itemBuilder: (context, index) {
          String item = menu.keys.elementAt(index);
          var itemData = menu[item];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade200, Colors.yellow.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      itemData['image'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  Text(
                    '\$${itemData['price']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<Cart>(context, listen: false).addItem(
                        item,
                        itemData['price'].toDouble(),
                        restaurant['name'],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$item added to cart')),
                      );
                    },
                    child: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (100 * index).ms);
        },
      ),
    );
  }
}
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Colors.teal,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Consumer<Cart>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Text(
                'Your cart is empty!',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    var item = cart.items[index];
                    return Slidable(
                      key: ValueKey(item.name),
                      endActionPane: ActionPane(
                        motion: ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              cart.items.removeAt(index);
                              cart.notifyListeners();
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Remove',
                          ),
                        ],
                      ),
                      child: GFCard( // Using GFCard for consistency
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 4,
                        content: ListTile(
                          leading: Icon(Icons.fastfood, color: Colors.teal),
                          title: Text(item.name, style: GoogleFonts.poppins()),
                          subtitle: Text('From: ${item.restaurantName}', style: GoogleFonts.poppins()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${item.price}',
                                style: GoogleFonts.poppins(color: Colors.yellow[700]),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  cart.items.removeAt(index);
                                  cart.notifyListeners();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item.name} removed from cart')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${cart.total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentScreen()),
                      ),
                      child: Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Colors.teal,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pay \$${cart.total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                cart.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment Successful!')),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Pay Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class GroceryScreen extends StatelessWidget {
  final List<List<Color>> gradients = [
    [Colors.blue.shade300, Colors.blue.shade700],
    [Colors.lime.shade300, Colors.lime.shade700],
    [Colors.pink.shade300, Colors.pink.shade700],
    [Colors.cyan.shade300, Colors.cyan.shade700],
    [Colors.amber.shade300, Colors.amber.shade700],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: mockGroceries.map((grocery) {
            int gradientIndex = mockGroceries.indexOf(grocery) % gradients.length;
            return StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: grocery['id'].isOdd ? 1.4 : 1.6,
              child: GFCard(
                gradient: LinearGradient(
                  colors: gradients[gradientIndex],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                elevation: 8, // Replaced boxShadow
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        grocery['image'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grocery['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$${grocery['price']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.yellow[200],
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Provider.of<Cart>(context, listen: false).addItem(
                                grocery['name'],
                                grocery['price'].toDouble(),
                                'Grocery Store',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${grocery['name']} added to cart')),
                              );
                            },
                            child: Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 600.ms, delay: (100 * gradientIndex).ms)
                  .scale(
                    begin: Offset(0.8, 0.8),
                    end: Offset(1, 1),
                    duration: 400.ms,
                  ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
class DiscoverScreen extends StatelessWidget {
  final List<List<Color>> gradients = [
    [Colors.purple.shade300, Colors.purple.shade700],
    [Colors.red.shade300, Colors.red.shade700],
    [Colors.teal.shade300, Colors.teal.shade700],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Featured Deals',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockDiscover.length,
              itemBuilder: (context, index) {
                var deal = mockDiscover[index];
                int gradientIndex = index % gradients.length;
                return SizedBox(
                  width: 250, // Moved width here
                  child: GFCard(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    gradient: LinearGradient(
                      colors: gradients[gradientIndex],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    elevation: 8,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            deal['image'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                deal['description'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.yellow[200],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: (100 * index).ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class OrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('Orders'));
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('Profile'));
}