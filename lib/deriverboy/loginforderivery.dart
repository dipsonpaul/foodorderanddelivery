import 'package:dbz/services/driversapi.dart';
import 'package:flutter/material.dart';
import 'package:dbz/deriverboy/driverdashboard.dart'; 

class DeliveryLoginPage extends StatefulWidget {
  const DeliveryLoginPage({Key? key}) : super(key: key);

  @override
  _DeliveryLoginPageState createState() => _DeliveryLoginPageState();
}

class _DeliveryLoginPageState extends State<DeliveryLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await DeliveryApiService.deliveryLogin(
        email: _emailController.text,
        password: _passwordController.text,
        onError: (errorMsg) {
          setState(() {
            _errorMessage = errorMsg;
          });
        },
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DeliveryDashboard()),
      );
    } catch (e) {
      if (_errorMessage.isEmpty) {
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Login'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              Icon(
                Icons.local_shipping,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 24),

              const Text(
                'Delivery Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LOGIN', style: TextStyle(fontSize: 16)),
              ),
              
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("BACK TO USER LOGIN"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}