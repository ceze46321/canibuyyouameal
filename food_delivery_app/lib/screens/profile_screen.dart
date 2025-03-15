import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final data = await authProvider.getProfile();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _upgradeRole(String newRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.upgradeRole(newRole);
      setState(() {
        userData!['role'] = newRole;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role upgraded to $newRole!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.logout();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('No profile data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${userData!['name']}', style: GoogleFonts.poppins(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Email: ${userData!['email']}', style: GoogleFonts.poppins(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Role: ${userData!['role']}', style: GoogleFonts.poppins(fontSize: 18)),
                      const SizedBox(height: 20),
                      if (userData!['role'] == 'customer') ...[
                        ElevatedButton(
                          onPressed: () => _upgradeRole('merchant'),
                          child: const Text('Upgrade to Merchant'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _upgradeRole('dasher'),
                          child: const Text('Upgrade to Dasher'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}