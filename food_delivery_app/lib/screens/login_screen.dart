import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final response = await Provider.of<AuthProvider>(context, listen: false).login(_email, _password);
        final role = response['user']['role'] ?? 'customer';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, $role!', style: GoogleFonts.poppins()), backgroundColor: accentColor),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          _animationController.reverse().then((_) => _animationController.forward()); // Shake effect on error
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final response = await Provider.of<AuthProvider>(context, listen: false)
          .loginWithGoogle(googleUser.email, googleAuth.accessToken!);
      final role = response['user']['role'] ?? 'customer';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $role! (Google)', style: GoogleFonts.poppins()), backgroundColor: accentColor),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Terms and Conditions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Text(
            '''
Welcome to Chiw Express! By signing in, you agree to:

1. **Usage**: Use the app for food orders, logistics, and groceries.
2. **Privacy**: We protect your data—see our policy at chiwexpress.com/privacy.
3. **Roles**: Choose Customer, Merchant, or Dasher roles with unique features.
4. **Payments**: Secure transactions, no refunds after delivery.
5. **Support**: Contact us at support@chiwexpress.com for help.

Full terms at chiwexpress.com/terms.
            ''',
            style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: GoogleFonts.poppins(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Text(
            '''
At Chiw Express, your privacy matters:

1. **Data Collection**: We collect email, name, and location for service delivery.
2. **Usage**: Data is used to process orders and improve your experience.
3. **Security**: Encrypted storage and secure transactions.
4. **Sharing**: Only shared with necessary partners (e.g., dashers, merchants).
5. **Rights**: Opt-out or delete your data anytime via support@chiwexpress.com.

Full policy at chiwexpress.com/privacy.
            ''',
            style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Understood', style: GoogleFonts.poppins(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to reset your password.', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reset link sent (coming soon)!', style: GoogleFonts.poppins()), backgroundColor: accentColor),
              );
              Navigator.pop(context);
            },
            child: Text('Send', style: GoogleFonts.poppins(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
        ],
      ),
    );
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
                colors: [primaryColor.withOpacity(0.9), accentColor.withOpacity(0.3), Colors.white],
              ),
            ),
            child: CustomPaint(
              painter: WavePainter(),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Intro
                      Animate(
                        effects: const [FadeEffect(), ScaleEffect()],
                        child: Column(
                          children: [
                            Image.network(
                              'https://i.imgur.com/22ZC89v.png', // Replace with your app logo
                              height: 100,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 100, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chiw Express',
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                              ),
                            ),
                            Text(
                              'Taste Nigeria, Delivered Fresh',
                              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login Form Card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                              BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 40, spreadRadius: 5), // Glow effect
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign In',
                                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unlock your food adventure',
                                  style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.6)),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  focusNode: _emailFocus,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    prefixIcon: const Icon(Icons.email, color: primaryColor),
                                  ),
                                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Valid email required' : null,
                                  onSaved: (value) => _email = value!,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  focusNode: _passwordFocus,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    prefixIcon: const Icon(Icons.lock, color: primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: primaryColor),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) => value!.length < 6 ? 'Password must be 6+ characters' : null,
                                  onSaved: (value) => _password = value!,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    child: Text('Forgot Password?', style: GoogleFonts.poppins(color: primaryColor, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _isLoading
                                    ? const Center(child: SpinKitPouringHourGlass(color: primaryColor, size: 50))
                                    : ElevatedButton(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white.withOpacity(0.2), // Ripple effect
                                          minimumSize: const Size(double.infinity, 56),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 6,
                                        ),
                                        child: Text('Sign In', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                                      ).animate().scale(duration: 300.ms),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-In
                      Row(children: [
                        Expanded(child: Divider(color: textColor.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Or Sign In With', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                        ),
                        Expanded(child: Divider(color: textColor.withOpacity(0.3))),
                      ]),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.network(
                            'https://static-00.iconduck.com/assets.00/google-icon-2048x673-w3o7skkh.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.grey),
                          ),
                          label: Text('Sign in with Google', style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor.withOpacity(0.2), // Ripple effect
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ).animate().scale(duration: 300.ms),
                      ),

                      // Benefits Carousel
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildBenefitCard(Icons.local_dining, 'Local Flavors', 'Authentic Nigerian cuisine'),
                            _buildBenefitCard(Icons.flash_on, 'Fast Delivery', 'Quick to your door'),
                            _buildBenefitCard(Icons.star, 'Top Rated', 'Loved by foodies'),
                          ],
                        ),
                      ),

                      // Enhanced Footer
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                                  child: Text('New here? Sign Up', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                                ),
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: _showTermsAndConditions,
                                  child: Text(
                                    'Terms',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: _showPrivacyPolicy,
                                  child: Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Join 10,000+ happy foodies! | v1.0.0',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String description) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: primaryColor),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          Text(description, style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.7)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// Custom Painter for Wave Background
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
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