import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _role = 'customer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the terms and conditions'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    _formKey.currentState!.save();
    print('Registering: name: $_name, email: $_email, password: $_password, role: $_role');
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _name,
        _email,
        _password,
        _role, // Removed context: context
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful'), backgroundColor: accentColor),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Registration failed: $e';
        if (e.toString().contains('Registration failed:')) {
          try {
            final errorJson = json.decode(e.toString().split('Registration failed: ')[1]);
            errorMessage = errorJson['error'] ?? errorMessage;
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms and Conditions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            '''
Welcome to Chiw Express! By signing up, you agree to:

1. **Usage**: Use the app for lawful purposes only.
2. **Account**: Keep your credentials secure; you’re responsible for all activity.
3. **Roles**: Your role (Customer, Merchant, Dasher) defines your permissions.
4. **Payments**: Transactions are processed securely; refunds follow our policy.
5. **Liability**: We’re not liable for third-party service issues.

Full terms at chiwexpress.com/terms.
            ''',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Chiw Express today!',
                      style: GoogleFonts.poppins(fontSize: 16, color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.person, color: primaryColor),
                              ),
                              validator: (value) => value!.isEmpty ? 'Name is required' : null,
                              onSaved: (value) => _name = value!,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.email, color: primaryColor),
                              ),
                              validator: (value) => value!.isEmpty || !value.contains('@') ? 'Valid email required' : null,
                              onSaved: (value) => _email = value!,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.lock, color: primaryColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: primaryColor,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) => value!.length < 6 ? 'Password must be 6+ characters' : null,
                              onSaved: (value) => _password = value!,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _role,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.person_outline, color: primaryColor),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                                DropdownMenuItem(value: 'merchant', child: Text('Merchant')),
                                DropdownMenuItem(value: 'dasher', child: Text('Dasher')),
                              ],
                              onChanged: (value) => setState(() => _role = value!),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) => setState(() => _acceptTerms = value!),
                                  activeColor: primaryColor,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTermsAndConditions,
                                    child: Text(
                                      'I agree to the Terms and Conditions',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'), // Changed to '/' instead of '/login'
                        child: Text(
                          'Already have an account? Login',
                          style: GoogleFonts.poppins(color: primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}