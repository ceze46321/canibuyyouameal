import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'services/api_service.dart';
import 'item.dart';

// New color palette
const primaryColor = Color(0xFFEF5350); // Vibrant red
const accentColor = Color(0xFF4CAF50);  // Fresh green
const backgroundColor = Color(0xFFF5F5F5); // Light gray
const textColor = Color(0xFF212121);   // Dark gray
const secondaryColor = Color(0xFFFFA726); // Warm orange
const highlightColor = Color(0xFF0288D1); // Bright blue

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flavor Rush',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: textColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: primaryColor,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BounceInDown(
                duration: const Duration(seconds: 1),
                child: const Icon(Icons.local_dining, size: 180, color: Colors.white),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Text(
                  'Flavor Rush',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  'Taste the world at your doorstep',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 60),
              FlipInX(
                duration: const Duration(milliseconds: 1200),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                  style: ElevatedButton.styleFrom(backgroundColor: highlightColor),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const RestaurantScreen(),
    const GroceryScreen(),
    const CartScreen(),
    const OrderScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
            BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: primaryColor,
          unselectedItemColor: textColor.withOpacity(0.6),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final data = await apiService.getRestaurants();
      setState(() {
        restaurants = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        leading: const Icon(Icons.restaurant),
      ),
      body: isLoading
          ? const Center(child: SpinKitCircle(color: accentColor, size: 50))
          : RefreshIndicator(
              onRefresh: _fetchRestaurants,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 200 + (index * 100)),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(restaurant['image'], height: 120, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(restaurant['name'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(restaurant['delivery_time'], style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  const MenuScreen({required this.restaurant, super.key});

  @override
  Widget build(BuildContext context) {
    final menu = restaurant['menu'] as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant['name']),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menu.length,
        itemBuilder: (context, index) {
          final itemName = menu.keys.elementAt(index);
          final itemData = menu[itemName];
          return SlideInLeft(
            duration: Duration(milliseconds: 200 + (index * 100)),
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(itemData['image'], width: 50, height: 50, fit: BoxFit.cover)),
                title: Text(itemName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('\$${itemData['price']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                trailing: ElevatedButton(
                  onPressed: () {
                    Provider.of<Cart>(context, listen: false).addItem(itemName, itemData['price'].toDouble(), restaurant['name']);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$itemName added to cart')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  child: const Text('Add'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> groceries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroceries();
  }

  Future<void> _fetchGroceries() async {
    try {
      final data = await apiService.getGroceries();
      setState(() {
        groceries = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groceries'),
        leading: const Icon(Icons.local_grocery_store),
      ),
      body: isLoading
          ? const Center(child: SpinKitFadingCircle(color: secondaryColor, size: 50))
          : RefreshIndicator(
              onRefresh: _fetchGroceries,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: groceries.length,
                itemBuilder: (context, index) {
                  final grocery = groceries[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 200 + (index * 100)),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(grocery['image'], height: 120, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(grocery['name'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('\$${grocery['price']} - ${grocery['delivery_time']}', style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        leading: const Icon(Icons.shopping_cart),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 120, color: textColor),
                  const SizedBox(height: 20),
                  Text('Your cart is empty', style: GoogleFonts.poppins(fontSize: 22, color: textColor)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantScreen())),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return SlideInRight(
                        duration: Duration(milliseconds: 200 + (index * 100)),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: accentColor,
                                  child: Text(item.name[0], style: const TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text('\$${item.price} - ${item.restaurantName}', style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: primaryColor),
                                  onPressed: () => cart.removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${cart.total.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await orderProvider.addOrder(cart.items, cart.total, notes: 'Quick order', isRush: false);
                            cart.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed!')));
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen()));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Place Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final data = await apiService.getOrders();
      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        leading: const Icon(Icons.receipt_long),
      ),
      body: isLoading
          ? const Center(child: SpinKitWave(color: highlightColor, size: 50))
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 120, color: textColor),
                          const SizedBox(height: 20),
                          Text('No orders yet', style: GoogleFonts.poppins(fontSize: 22, color: textColor)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return FadeInUp(
                          duration: Duration(milliseconds: 200 + (index * 100)),
                          child: Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Order #${order['id']}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: order['status'] == 'Placed' ? secondaryColor : accentColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(order['status'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Total: \$${order['total']}', style: GoogleFonts.poppins(fontSize: 16, color: primaryColor)),
                                  const SizedBox(height: 8),
                                  Text('Notes: ${order['notes'] ?? 'None'}', style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7))),
                                  const SizedBox(height: 8),
                                  Text('Items:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ...(order['items'] as List).map((item) => Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 4),
                                        child: Text('• ${item['name']} (\$${item['price']})', style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7))),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: const Icon(Icons.person),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: primaryColor,
                        child: Icon(Icons.person, size: 80, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text('User Name', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('user@example.com', style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7))),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRestaurantScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Add Restaurant'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGroceryScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: highlightColor, minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Add Grocery'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor),
                          minimumSize: const Size(double.infinity, 50),
                          foregroundColor: primaryColor,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  String name = '';
  String image = '';
  String deliveryTime = '';
  String menuItemName = '';
  String menuItemPrice = '';
  String menuItemImage = '';
  Map<String, dynamic> menu = {};

  void _addMenuItem() {
    if (menuItemName.isNotEmpty && menuItemPrice.isNotEmpty) {
      setState(() {
        menu[menuItemName] = {'price': double.parse(menuItemPrice), 'image': menuItemImage.isEmpty ? 'https://via.placeholder.com/150' : menuItemImage};
        menuItemName = '';
        menuItemPrice = '';
        menuItemImage = '';
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await apiService.addRestaurant(name, image, deliveryTime, menu);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant added!')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Restaurant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => name = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => image = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Delivery Time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => deliveryTime = value!,
                ),
                const SizedBox(height: 24),
                Text('Menu Items', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => menuItemName = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Item Price',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => menuItemPrice = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Item Image URL (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => menuItemImage = value,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addMenuItem,
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  child: const Text('Add Item'),
                ),
                const SizedBox(height: 16),
                Text('Menu: ${menu.entries.map((e) => '${e.key}: \$${e.value['price']}').join(', ')}', style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Submit Restaurant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddGroceryScreen extends StatefulWidget {
  const AddGroceryScreen({super.key});

  @override
  State<AddGroceryScreen> createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  String name = '';
  String image = '';
  String price = '';
  String deliveryTime = '';

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await apiService.addGrocery(name, image, double.parse(price), deliveryTime);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grocery added!')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Grocery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => name = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => image = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => price = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Delivery Time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => deliveryTime = value!,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Submit Grocery'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}