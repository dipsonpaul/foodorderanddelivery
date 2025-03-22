
import 'package:dbz/Auth/loginform.dart';
import 'package:dbz/Auth/signup.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and welcome text
                Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLogin ? 'Welcome Back!' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin
                          ? 'Sign in to continue'
                          : 'Sign up to get started',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                  
                  ],
                ),

                // Auth form
                isLogin ? const LoginForm() : const SignupForm(),

                // Toggle between login and signup
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin
                          ? 'Don\'t have an account?'
                          : 'Already have an account?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(
                        isLogin ? 'Sign Up' : 'Sign In',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
