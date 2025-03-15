import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class GroceryScreen extends StatelessWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Groceries', style: GoogleFonts.poppins()), backgroundColor: primaryColor),
      body: const Center(child: Text('Grocery feature coming soon!')),
    );
  }
}