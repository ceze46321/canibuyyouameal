import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:animate_do/animate_do.dart';
import 'data/mock_data.dart';
import 'models/item.dart';
import 'services/notification_service.dart';

// Brand Colors
const Color brandTeal = Color(0xFF26A69A);
const Color brandOrange = Color(0xFFFF7043);
const Color brandCream = Color(0xFFFFF8E1);
const Color brandGray = Color(0xFF37474F);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MyApp(notificationService: notificationService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  MyApp({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery',
      theme: ThemeData(
        primaryColor: brandTeal,
        scaffoldBackgroundColor: brandCream,
        appBarTheme: AppBarTheme(
          backgroundColor: brandTeal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: HomeScreen(notificationService: notificationService),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final NotificationService notificationService;
  HomeScreen({required this.notificationService});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      RestaurantScreen(),
      GroceryScreen(),
      DiscoverScreen(),
      OrderScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FoodieHub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          Bounce(
            animate: Provider.of<Cart>(context).items.isNotEmpty,
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.shopping_cart),
                  if (Provider.of<Cart>(context).items.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: brandOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${Provider.of<Cart>(context).items.length}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen(notificationService: widget.notificationService)),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: GlassContainer.frostedGlass(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        blur: 10,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: brandOrange,
          unselectedItemColor: brandGray,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Grocery'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class RestaurantScreen extends StatelessWidget {
  final List<List<Color>> gradients = [
    [brandTeal.withOpacity(0.8), brandTeal],
    [brandOrange.withOpacity(0.8), brandOrange],
    [Colors.purple.shade400, Colors.purple.shade700],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurants',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: brandGray),
            ).animate().fadeIn(duration: 500.ms),
            SizedBox(height: 16),
            StaggeredGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: mockRestaurants.map((restaurant) {
                int gradientIndex = mockRestaurants.indexOf(restaurant) % gradients.length;
                return StaggeredGridTile.count(
                  crossAxisCellCount: 1,
                  mainAxisCellCount: restaurant['id'].isOdd ? 1.5 : 1.2,
                  child: BounceInDown(
                    child: GlassContainer.frostedGlass(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: gradients[gradientIndex],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MenuScreen(restaurant: restaurant)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                restaurant['image'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 120,
                                  color: brandGray,
                                  child: Center(child: Text('Image Error', style: TextStyle(color: brandCream))),
                                ),
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
                                      color: brandCream,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap to Explore',
                                    style: GoogleFonts.poppins(fontSize: 14, color: brandCream.withOpacity(0.8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
        title: Text(restaurant['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [brandTeal, brandTeal.withOpacity(0.8)]),
          ),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: menu.length,
        itemBuilder: (context, index) {
          String item = menu.keys.elementAt(index);
          var itemData = menu[item];
          return FlipInY(  // Replaced 'Flip' with 'FlipInY'
            child: GlassContainer.frostedGlass(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [brandOrange.withOpacity(0.7), brandOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      itemData['image'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: brandGray,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: brandCream),
                        ),
                        Text(
                          '\$${itemData['price']}',
                          style: GoogleFonts.poppins(fontSize: 14, color: brandCream.withOpacity(0.8)),
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
                              SnackBar(
                                content: Text('$item added to cart', style: TextStyle(color: brandCream)),
                                backgroundColor: brandTeal,
                              ),
                            );
                          },
                          child: Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final NotificationService notificationService;
  CartScreen({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [brandTeal, brandTeal.withOpacity(0.8)]),
          ),
        ),
      ),
      body: Consumer<Cart>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Text(
                'Cart is empty!',
                style: GoogleFonts.poppins(fontSize: 20, color: brandGray),
              ).animate().fadeIn(),
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
                      child: BounceInRight(
                        child: GlassContainer.frostedGlass(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [brandGray.withOpacity(0.7), brandGray],
                          ),
                          child: ListTile(
                            leading: Icon(Icons.fastfood, color: brandOrange),
                            title: Text(item.name, style: GoogleFonts.poppins(color: brandCream)),
                            subtitle: Text('From: ${item.restaurantName}', style: GoogleFonts.poppins(color: brandCream.withOpacity(0.7))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$${item.price}', style: GoogleFonts.poppins(color: brandOrange)),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    cart.items.removeAt(index);
                                    cart.notifyListeners();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${item.name} removed', style: TextStyle(color: brandCream)),
                                        backgroundColor: brandTeal,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              GlassContainer.frostedGlass(
                padding: EdgeInsets.all(16),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(colors: [brandTeal.withOpacity(0.8), brandTeal]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${cart.total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: brandCream),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentScreen(notificationService: notificationService)),
                      ),
                      child: Text('Checkout'),
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
  final NotificationService notificationService;
  PaymentScreen({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [brandTeal, brandTeal.withOpacity(0.8)]),
          ),
        ),
      ),
      body: Center(
        child: GlassContainer.frostedGlass(
          padding: EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [brandGray.withOpacity(0.7), brandGray]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pay \$${cart.total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: brandCream),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  orderProvider.addOrder(cart.items, cart.total);
                  notificationService.showNotification('Order Placed', 'Your order is on its way!');
                  cart.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment Successful!', style: TextStyle(color: brandCream)),
                      backgroundColor: brandTeal,
                    ),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('Pay Now'),
              ),
            ],
          ),
        ).animate().scale(),
      ),
    );
  }
}

class GroceryScreen extends StatelessWidget {
  final List<List<Color>> gradients = [
    [brandTeal.withOpacity(0.7), brandTeal],
    [brandOrange.withOpacity(0.7), brandOrange],
    [Colors.green.shade400, Colors.green.shade700],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Groceries',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: brandGray),
            ).animate().fadeIn(duration: 500.ms),
            SizedBox(height: 16),
            StaggeredGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: mockGroceries.map((grocery) {
                int gradientIndex = mockGroceries.indexOf(grocery) % gradients.length;
                return StaggeredGridTile.count(
                  crossAxisCellCount: 1,
                  mainAxisCellCount: grocery['id'].isOdd ? 1.4 : 1.6,
                  child: BounceInUp(
                    child: GlassContainer.frostedGlass(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: gradients[gradientIndex],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              grocery['image'],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: brandGray,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  grocery['name'],
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: brandCream),
                                ),
                                Text(
                                  '\$${grocery['price']}',
                                  style: GoogleFonts.poppins(fontSize: 14, color: brandCream.withOpacity(0.8)),
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
                                      SnackBar(
                                        content: Text('${grocery['name']} added', style: TextStyle(color: brandCream)),
                                        backgroundColor: brandTeal,
                                      ),
                                    );
                                  },
                                  child: Text('Add'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverScreen extends StatelessWidget {
  final List<List<Color>> gradients = [
    [brandOrange.withOpacity(0.7), brandOrange],
    [brandTeal.withOpacity(0.7), brandTeal],
    [Colors.red.shade400, Colors.red.shade700],
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
              'Discover Deals',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: brandGray),
            ).animate().fadeIn(duration: 500.ms),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockDiscover.length,
              itemBuilder: (context, index) {
                var deal = mockDiscover[index];
                int gradientIndex = index % gradients.length;
                return SizedBox(
                  width: 260,
                  child: BounceInLeft(
                    child: GlassContainer.frostedGlass(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: gradients[gradientIndex],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              deal['image'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: brandGray,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deal['title'],
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: brandCream),
                                ),
                                Text(
                                  deal['description'],
                                  style: GoogleFonts.poppins(fontSize: 14, color: brandCream.withOpacity(0.8)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
        ],
      ),
    );
  }
}

class OrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.orders.isEmpty) {
          return Center(
            child: Text(
              'No orders yet!',
              style: GoogleFonts.poppins(fontSize: 20, color: brandGray),
            ).animate().fadeIn(),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orderProvider.orders.length,
          itemBuilder: (context, index) {
            final order = orderProvider.orders[index];
            Color statusColor;
            switch (order.status) {
              case 'Placed':
                statusColor = Colors.blue;
                break;
              case 'Preparing':
                statusColor = brandOrange;
                break;
              case 'Out for Delivery':
                statusColor = Colors.purple;
                break;
              case 'Delivered':
                statusColor = Colors.green;
                break;
              default:
                statusColor = brandGray;
            }
            return BounceInUp(
              child: GlassContainer.frostedGlass(
                margin: EdgeInsets.symmetric(vertical: 8),
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [brandGray.withOpacity(0.7), brandGray]),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: brandCream),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Status: ', style: GoogleFonts.poppins(color: brandCream)),
                          Text(order.status, style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('Total: \$${order.total.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: brandCream)),
                      Text('Placed: ${order.placedAt.toString().substring(0, 19)}', style: GoogleFonts.poppins(color: brandCream)),
                      SizedBox(height: 8),
                      Text('Items:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: brandCream)),
                      ...order.items.map((item) => Text(
                            '${item.name} - \$${item.price}',
                            style: GoogleFonts.poppins(color: brandCream.withOpacity(0.8)),
                          )),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassContainer.frostedGlass(
        padding: EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [brandTeal.withOpacity(0.7), brandTeal]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: brandOrange,
              child: Icon(Icons.person, size: 60, color: brandCream),
            ).animate().scale(),
            SizedBox(height: 16),
            Text(
              'John Doe',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: brandCream),
            ),
            Text(
              'johndoe@example.com',
              style: GoogleFonts.poppins(fontSize: 16, color: brandCream.withOpacity(0.8)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
