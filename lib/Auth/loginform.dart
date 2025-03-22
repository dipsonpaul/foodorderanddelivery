import 'package:dbz/deriverboy/loginforderivery.dart';
import 'package:dbz/mainuser.dart';
import 'package:dbz/services/uapiserive.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the ApiService instead of direct HTTP call
      final responseData = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Store user_id (token is already stored by ApiService)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', responseData['user_id'].toString());

      // Navigate to home screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MainScreen()));
    } catch (error) {
      setState(() {
        // Extract error message from exception
        final errorString = error.toString();
        if (errorString.contains('API Error')) {
          // Try to parse the API error message
          final startIndex = errorString.indexOf('{');
          final endIndex = errorString.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1) {
            try {
              final errorJson = errorString.substring(startIndex, endIndex + 1);
              final errorMap = Map<String, dynamic>.from(
                errorJson as Map<String, dynamic>,
              );
              _errorMessage =
                  errorMap['detail'] ??
                  'Login failed. Please check your credentials.';
            } catch (_) {
              _errorMessage = 'Login failed. Please check your credentials.';
            }
          } else {
            _errorMessage = 'Login failed. Please check your credentials.';
          }
        } else {
          _errorMessage =
              'Connection error. Please check your internet connection.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Login button
          ElevatedButton(
            onPressed:
                _isLoading
                    ? null
                    : () {
                      if (_formKey.currentState!.validate()) {
                        _login();
                      }
                    },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
          SizedBox(height: 15),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryLoginPage()),
              );
            },
            child: Text("DELIVERY BOYS LOGIN"),
          ),
        ],
      ),
    );
  }
}
