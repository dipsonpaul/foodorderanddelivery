// Delivered Orders Screen (History Screen)
import 'package:dbz/deriverboy/driverdashboard.dart';
import 'package:dbz/services/driversapi.dart';
import 'package:dbz/deriverboy/loginforderivery.dart';
import 'package:flutter/material.dart';

class DeliveredOrdersScreen extends StatefulWidget {
  const DeliveredOrdersScreen({Key? key}) : super(key: key);

  @override
  _DeliveredOrdersScreenState createState() => _DeliveredOrdersScreenState();
}

class _DeliveredOrdersScreenState extends State<DeliveredOrdersScreen> {
  List<Order> _deliveredOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if logged in
      final isLoggedIn = await DeliveryApiService.isDeliveryPersonLoggedIn();
      if (!isLoggedIn) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeliveryLoginPage ()),
        );
        return;
      }

      // Get assigned orders using the new API service
      final data = await DeliveryApiService.getAssignedOrders();

      if (data['message'] == 'Orders retrieved successfully.') {
        final List<dynamic> ordersJson = data['orders'];
        final List<Order> allOrders =
            ordersJson.map((orderJson) => Order.fromJson(orderJson)).toList();

        // Filter for delivered orders only
        setState(() {
          _deliveredOrders =
              allOrders.where((order) => order.status == 'delivered').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to parse orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchOrders, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_deliveredOrders.isEmpty) {
      return const Center(child: Text('No delivered orders available'));
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        itemCount: _deliveredOrders.length,
        itemBuilder: (context, index) {
          final order = _deliveredOrders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order ID: ${order.orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Delivered',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Address: ${order.address}'),
                  const SizedBox(height: 8),
                  Text('Phone: ${order.phone}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
