import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color warmCoral = Color(0xFFFF7043);
  static const Color deepBrown = Color(0xFF3E2723);

  // Controllers for input fields
  final _menuIdController = TextEditingController();
  final _menuPriceController = TextEditingController();
  final _groceryIdController = TextEditingController();
  final _groceryPriceController = TextEditingController();
  final _emailSubjectController = TextEditingController();
  final _emailMessageController = TextEditingController();
  final _emailRecipientController = TextEditingController();

  // Show list dialog for users, dashers, etc.
  Future<void> _showListDialog(BuildContext context, String title, Future<List<dynamic>> Function() fetchFunction) async {
    try {
      final items = await fetchFunction();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: doorDashRed)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Fixed height for scrollable content
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['name'] ?? 'Unnamed', style: GoogleFonts.poppins()),
                  subtitle: Text(item['email'] ?? 'No email', style: GoogleFonts.poppins(color: Colors.grey)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.poppins(color: doorDashRed)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load $title: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Show price update dialog
  Future<void> _showPriceUpdateDialog(
    BuildContext context,
    String type,
    TextEditingController idController,
    TextEditingController priceController,
    Future<void> Function(String, double) updateFunction,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $type Price', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: '$type ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'New Price', border: OutlineInputBorder()),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = idController.text.trim();
              final priceText = priceController.text.trim();
              if (id.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              final price = double.tryParse(priceText);
              if (price == null || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid price')),
                );
                return;
              }
              try {
                await updateFunction(id, price);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$type price updated successfully')),
                );
                idController.clear();
                priceController.clear();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update $type price: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: warmCoral),
            child: Text('Update', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // Show email sending dialog
  Future<void> _showEmailDialog(BuildContext context, AuthProvider authProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Email', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailRecipientController,
                decoration: const InputDecoration(labelText: 'Recipient Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailSubjectController,
                decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailMessageController,
                decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          ElevatedButton(
            onPressed: () async {
              final recipient = _emailRecipientController.text.trim();
              final subject = _emailSubjectController.text.trim();
              final message = _emailMessageController.text.trim();
              if (recipient.isEmpty || subject.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              try {
                await authProvider.sendAdminEmail(subject, message, recipient);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email sent successfully')),
                );
                _emailRecipientController.clear();
                _emailSubjectController.clear();
                _emailMessageController.clear();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send email: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: warmCoral),
            child: Text('Send', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _menuIdController.dispose();
    _menuPriceController.dispose();
    _groceryIdController.dispose();
    _groceryPriceController.dispose();
    _emailSubjectController.dispose();
    _emailMessageController.dispose();
    _emailRecipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            'Unauthorized Access',
            style: GoogleFonts.poppins(fontSize: 24, color: deepBrown),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: doorDashRed,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${authProvider.name ?? "Admin"}!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: deepBrown,
              ),
            ),
            const SizedBox(height: 20),

            // User Management Section
            _buildSectionTitle('User Management'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  'All Users',
                  () => _showListDialog(context, 'All Users', authProvider.fetchAllUsers),
                ),
                _buildActionButton(
                  context,
                  'Dashers',
                  () => _showListDialog(context, 'Dashers', authProvider.fetchDashers),
                ),
                _buildActionButton(
                  context,
                  'Restaurant Owners',
                  () => _showListDialog(context, 'Restaurant Owners', authProvider.fetchRestaurantOwners),
                ),
                _buildActionButton(
                  context,
                  'Customers',
                  () => _showListDialog(context, 'Customers', authProvider.fetchCustomers),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price Management Section
            _buildSectionTitle('Price Management'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  'Update Menu Price',
                  () => _showPriceUpdateDialog(
                    context,
                    'Menu',
                    _menuIdController,
                    _menuPriceController,
                    authProvider.updateMenuPrice,
                  ),
                ),
                _buildActionButton(
                  context,
                  'Update Grocery Price',
                  () => _showPriceUpdateDialog(
                    context,
                    'Grocery',
                    _groceryIdController,
                    _groceryPriceController,
                    authProvider.updateGroceryItemPrice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email Section
            _buildSectionTitle('Communication'),
            _buildActionButton(
              context,
              'Send Email',
              () => _showEmailDialog(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: deepBrown,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: warmCoral,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}