import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor, secondaryColor;
import 'package:flutter_animate/flutter_animate.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _address = '';
  String _state = '';
  String _country = '';
  String _category = 'Restaurant';
  String? _imageUrl;
  final List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addMenuItem() {
    setState(() {
      _menuItems.add({'name': '', 'price': 0.0, 'quantity': 1});
    });
  }

  void _removeMenuItem(int index) {
    setState(() {
      _menuItems.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_menuItems.isEmpty || _menuItems.any((item) => item['name'].isEmpty || item['price'] <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add at least one valid menu item', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthProvider>(context, listen: false).addRestaurant(
          _name,
          _address,
          _state,
          _country,
          _category,
          image: _imageUrl,
          menuItems: _menuItems,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restaurant added successfully!', style: GoogleFonts.poppins()),
              backgroundColor: accentColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add restaurant: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.6),
                  secondaryColor.withOpacity(0.2),
                  const Color(0xFFF5F5F5),
                ],
              ),
            ),
            child: CustomPaint(painter: WavePainter()),
          ),
          SafeArea(
            child: _isLoading
                ? Center(child: SpinKitFadingCircle(color: primaryColor, size: 50))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFF7043)),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Text(
                                    'Add Your Restaurant',
                                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 48), // Balance for back button
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form Card
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              shadowColor: primaryColor.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Restaurant Details',
                                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Restaurant Name',
                                        labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                        prefixIcon: const Icon(Icons.store, color: Color(0xFFFF7043)),
                                        filled: true,
                                        fillColor: const Color(0xFFF5F5F5),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Name required' : null,
                                      onSaved: (value) => _name = value!,
                                      style: GoogleFonts.poppins(color: textColor),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Address',
                                        labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF7043)),
                                        filled: true,
                                        fillColor: const Color(0xFFF5F5F5),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Address required' : null,
                                      onSaved: (value) => _address = value!,
                                      style: GoogleFonts.poppins(color: textColor),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              labelText: 'State',
                                              labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                              prefixIcon: const Icon(Icons.map, color: Color(0xFFFF7043)),
                                              filled: true,
                                              fillColor: const Color(0xFFF5F5F5),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            ),
                                            validator: (value) => value!.isEmpty ? 'State required' : null,
                                            onSaved: (value) => _state = value!,
                                            style: GoogleFonts.poppins(color: textColor),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              labelText: 'Country',
                                              labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                              prefixIcon: const Icon(Icons.flag, color: Color(0xFFFF7043)),
                                              filled: true,
                                              fillColor: const Color(0xFFF5F5F5),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            ),
                                            validator: (value) => value!.isEmpty ? 'Country required' : null,
                                            onSaved: (value) => _country = value!,
                                            style: GoogleFonts.poppins(color: textColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _category,
                                      decoration: InputDecoration(
                                        labelText: 'Category',
                                        labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                        prefixIcon: const Icon(Icons.category, color: Color(0xFFFF7043)),
                                        filled: true,
                                        fillColor: const Color(0xFFF5F5F5),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                      items: ['Restaurant', 'Fast Food', 'Cafe'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins(color: textColor)))).toList(),
                                      onChanged: (value) => setState(() => _category = value!),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Image URL (optional)',
                                        labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                        prefixIcon: const Icon(Icons.image, color: Color(0xFFFF7043)),
                                        filled: true,
                                        fillColor: const Color(0xFFF5F5F5),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                      validator: (value) => value != null && value.isNotEmpty && !(Uri.tryParse(value)?.isAbsolute ?? false) ? 'Invalid URL' : null,
                                      onSaved: (value) => _imageUrl = value?.isEmpty ?? true ? null : value,
                                      style: GoogleFonts.poppins(color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Menu Items Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              shadowColor: primaryColor.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Menu Items',
                                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    const SizedBox(height: 16),
                                    ..._menuItems.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return Animate(
                                        effects: const [FadeEffect(), SlideEffect()],
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText: 'Item Name',
                                                    labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                                    prefixIcon: const Icon(Icons.fastfood, color: Color(0xFFFF7043)),
                                                    filled: true,
                                                    fillColor: const Color(0xFFF5F5F5),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                                  ),
                                                  validator: (value) => value!.isEmpty ? 'Name required' : null,
                                                  onChanged: (value) => item['name'] = value,
                                                  style: GoogleFonts.poppins(color: textColor),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 100,
                                                child: TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText: 'Price',
                                                    labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFF7043)),
                                                    filled: true,
                                                    fillColor: const Color(0xFFF5F5F5),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  validator: (value) => value!.isEmpty || double.tryParse(value) == null ? 'Valid price' : null,
                                                  onChanged: (value) => item['price'] = double.tryParse(value) ?? 0.0,
                                                  style: GoogleFonts.poppins(color: textColor),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                onPressed: () => _removeMenuItem(index),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _addMenuItem,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text('Add Menu Item', style: GoogleFonts.poppins(fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: secondaryColor,
                                        foregroundColor: Colors.white.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      ),
                                    ).animate().scale(duration: 300.ms),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white.withOpacity(0.2),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: Text('Submit Restaurant', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                            ).animate().scale(duration: 300.ms),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Wave Painter for Background
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}