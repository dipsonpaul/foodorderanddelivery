import 'package:dbz/deriverboy/driverdashboard.dart';
import 'package:dbz/services/driversapi.dart';
import 'package:dbz/deriverboy/loginforderivery.dart';
import 'package:dbz/orderpage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({Key? key}) : super(key: key);

  @override
  _PendingOrdersScreenState createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List<Order> _assignedOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isUpdatingOrder = false;
  String _selectedStatusFilter =
      OrderStatus.outForDelivery; // Default to out_for_delivery

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

      // Get assigned orders using the API service
      final data = await DeliveryApiService.getAssignedOrders();

      if (data['message'] == 'Orders retrieved successfully.') {
        final List<dynamic> ordersJson = data['orders'];
        final List<Order> allOrders =
            ordersJson.map((orderJson) => Order.fromJson(orderJson)).toList();

        // Filter orders based on the selected status filter
        setState(() {
          _assignedOrders =
              allOrders
                  .where(
                    (order) =>
                        _selectedStatusFilter == null ||
                        order.status == _selectedStatusFilter,
                  )
                  .toList();
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

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    setState(() {
      _isUpdatingOrder = true;
    });

    try {
      // Use the API service to update order status
      await DeliveryApiService.updateOrderStatus(orderId, newStatus);

      if (!mounted) return;

      // Remove the delivered order from the list
      setState(() {
        _assignedOrders.removeWhere((order) => order.id == orderId);
        _isUpdatingOrder = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as ${OrderStatus.labels[newStatus]} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      if (!mounted) return;
      setState(() {
        _isUpdatingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openGoogleMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates not available')),
      );
      return;
    }

    try {
      // Get current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final url =
          'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$lat,$lng&travelmode=driving';

      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: ${e.toString()}')),
      );
    }
  }

  Future<void> _callCustomer(String phone) async {
    final url = 'tel:$phone';
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }

  Future<void> _confirmDelivery(Order order) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delivery'),
          content: Text(
            'Are you sure you want to mark order ${order.orderId} as delivered?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateOrderStatus(order.id, OrderStatus.delivered);
              },
              child: const Text('Confirm'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Assigned Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
        ],
      ),
      body: Column(children: [Expanded(child: _buildBody())]),
    );
  }

  Widget _buildBody() {
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

    if (_assignedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders to deliver',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _fetchOrders, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchOrders,
          child: ListView.builder(
            itemCount: _assignedOrders.length,
            itemBuilder: (context, index) {
              final order = _assignedOrders[index];
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
                              color: OrderStatus.getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              OrderStatus.labels[order.status] ?? order.status,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Address: ${order.address}'),
                      const SizedBox(height: 8),
                      Text('Phone: ${order.phone}'),
                      const SizedBox(height: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _callCustomer(order.phone),
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Call',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => _openGoogleMaps(
                                    order.latitude,
                                    order.longitude,
                                  ),
                              icon: const Icon(
                                Icons.directions,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Navigate',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                          if (order.status == OrderStatus.outForDelivery)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmDelivery(order),
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Deliver',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Overlay loading indicator when updating an order
        if (_isUpdatingOrder)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
