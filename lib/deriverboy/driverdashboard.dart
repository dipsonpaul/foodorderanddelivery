import 'package:dbz/deriverboy/deliverorderscreen.dart';
import 'package:dbz/services/driversapi.dart';
import 'package:dbz/deriverboy/loginforderivery.dart';
import 'package:dbz/deriverboy/pendingorders.dart';
import 'package:flutter/material.dart';

// Order model class remains the same
class Order {
  final int id;
  final String orderId;
  final String address;
  final String status;
  final String phone;
  final double? latitude;
  final double? longitude;

  Order({
    required this.id,
    required this.orderId,
    required this.address,
    required this.status,
    required this.phone,
    this.latitude,
    this.longitude,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderId: json['order_id'],
      address: json['address'],
      status: json['status'],
      phone: json['phone'],
      latitude:
          json['latitude'] != null
              ? double.parse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.parse(json['longitude'].toString())
              : null,
    );
  }
}

// Main dashboard after login with bottom navigation
class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({Key? key}) : super(key: key);

  @override
  _DeliveryDashboardState createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const PendingOrdersScreen(),
    const DeliveredOrdersScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: const Text('Delivery Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Use the new API service for logout
              await DeliveryApiService.clearDeliveryUserData();

              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DeliveryLoginPage ()),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.done_all),
            label: 'Delivered',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
