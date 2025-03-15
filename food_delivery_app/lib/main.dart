import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/restaurant_screen.dart';
import 'screens/restaurant_profile_screen.dart';
import 'screens/order_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/grocery_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/logistics_screen.dart';
import 'screens/dasher_screen.dart'; // Re-added
import 'screens/restaurant_owner_screen.dart'; // Re-added
import 'screens/profile_screen.dart'; // New ProfileScreen

const primaryColor = Color(0xFFE63946);
const accentColor = Color(0xFF4CAF50);
const secondaryColor = Color(0xFFFF9800);
const backgroundColor = Color(0xFFFFF8E1);
const textColor = Color(0xFF212121);

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
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
      title: 'Chiw Express',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: textColor),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScreen(initialIndex: 0),
        '/restaurants': (context) => const MainScreen(initialIndex: 1),
        '/orders': (context) => const MainScreen(initialIndex: 2),
        '/logistics': (context) => const MainScreen(initialIndex: 3),
        '/groceries': (context) => const MainScreen(initialIndex: 4),
        '/dashers': (context) => const MainScreen(initialIndex: 5), // New route
        '/restaurant-owners': (context) => const MainScreen(initialIndex: 6), // New route
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(), // New profile route
      },
    );
  }
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _userId;
  String? _name;
  String? _email;
  String? _token;
  String? _role; // Added role

  AuthProvider(this._apiService);

  bool get isLoggedIn => _token != null;
  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role; // Getter for role

  Future<void> register(String name, String email, String password, String role, {required BuildContext context}) async {
    final data = await _apiService.register(name, email, password, role);
    _userId = data['user']['id'].toString();
    _name = data['user']['name'];
    _email = data['user']['email'];
    _token = data['token'];
    _role = data['user']['role']; // Store role from registration
    _apiService.setToken(_token!);
    Navigator.pushReplacementNamed(context, '/home');
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _apiService.login(email, password);
    _userId = data['user']['id'].toString();
    _name = data['user']['name'];
    _email = data['user']['email'];
    _token = data['token'];
    _role = data['user']['role']; // Store role from login
    _apiService.setToken(_token!);
    notifyListeners();
    return data; // Return data for LoginScreen to use
  }

  Future<Map<String, dynamic>> loginWithGoogle(String email, String accessToken) async {
    // Simulate Google login by using regular login with a placeholder password
    // Replace this with a dedicated /api/google-login endpoint later
    final data = await _apiService.login(email, 'google-auth-placeholder-$accessToken');
    _userId = data['user']['id'].toString();
    _name = data['user']['name'];
    _email = data['user']['email'];
    _token = data['token'];
    _role = data['user']['role'] ?? 'customer'; // Default to customer if not provided
    _apiService.setToken(_token!);
    notifyListeners();
    return data;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _userId = null;
    _name = null;
    _email = null;
    _token = null;
    _role = null; // Clear role on logout
    notifyListeners();
  }

  Future<Map<String, dynamic>> getProfile() async => await _apiService.getProfile();

  Future<void> updateProfile(String name, String email, {Map<String, dynamic>? restaurantDetails}) async {
    await _apiService.updateProfile(name, email, restaurantDetails: restaurantDetails);
    _name = name;
    _email = email;
    notifyListeners();
  }

  // New method to upgrade role
  Future<void> upgradeRole(String newRole) async {
    final data = await _apiService.upgradeRole(newRole);
    _role = data['user']['role'];
    notifyListeners();
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, required this.initialIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> _getScreens(String? role) {
    // Base screens available to all roles
    List<Widget> screens = [
      const HomeScreen(),
      const RestaurantScreen(),
      const OrderScreen(),
      const LogisticsScreen(),
      const GroceryScreen(),
      const DasherScreen(), // Added empty screen
      const RestaurantOwnerScreen(), // Added empty screen
    ];

    // Add ProfileScreen for all logged-in users
    screens.add(const ProfileScreen());

    return screens;
  }

  List<BottomNavigationBarItem> _getNavItems(String? role) {
    // Base items available to all roles
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
      const BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Logistics'),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Groceries'),
      const BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Dashers'),
      const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Restaurants'), // Merchant-specific
    ];

    // Add Profile tab for all logged-in users
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screens = _getScreens(authProvider.role);
    final navItems = _getNavItems(authProvider.role);

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Use fixed type for more than 4 items
        items: navItems,
      ),
    );
  }
}