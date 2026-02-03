import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/auth/presentation/screens/branch_selection_screen.dart';
import 'package:dautari_adda/features/auth/presentation/screens/signup_screen.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import 'package:dautari_adda/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _retainLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Login logic
      await AuthService().login(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        ToastService.show(context, "Login Successful");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
        );
      }
    } catch (e) {
      ToastService.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/dautari-logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // App Name
                      Text(
                        'Dautari Adda',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back! Please login to your account.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 56),
                      
                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Remember Me
                      Row(
                        children: [
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: _retainLogin,
                              activeColor: const Color(0xFFFFC107),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                              onChanged: (value) {
                                setState(() {
                                  _retainLogin = value ?? false;
                                });
                              },
                            ),
                          ),
                          Text(
                            "Remember me",
                            style: GoogleFonts.poppins(
                              color: Colors.black54, 
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFFC107),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button
                      SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFFFFC107).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Don't have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                               Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const SignupScreen()),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFFC107),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                       const SizedBox(height: 32),

                      // Terms Text
                      Text(
                        "By logging in, you agree to Dautari Adda hospitality terms and conditions.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[400],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
              child: Text(
                'Powered by Ratala IT Company',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            style: GoogleFonts.poppins(fontSize: 15),
            cursorColor: const Color(0xFFFFC107),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (label == 'Email' &&
                  !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }
}

