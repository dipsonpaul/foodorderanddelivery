import 'package:dbz/home.dart';
import 'package:dbz/mainuser.dart';
import 'package:flutter/material.dart';

class OrderSuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Success')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      ),
                  child: Text("BACK TO HOME"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
