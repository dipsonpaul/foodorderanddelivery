import 'package:dbz/services/uapiserive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  final dynamic orderId;

  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _orderDetails = {};
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      // Convert orderId to int if it's not already
      final id =
          widget.orderId is int
              ? widget.orderId
              : int.tryParse(widget.orderId.toString()) ?? 0;

      final details = await ApiService.getOrderDetails(id);
      setState(() {
        _orderDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = true;
      });
      _showErrorSnackBar('Failed to load order details: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper method to safely convert values to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDeliverySection() {
    final address = _orderDetails['address'] ?? 'N/A';
    final phoneNumber = _orderDetails['phone'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(address),
              subtitle: const Text('Delivery Address'),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () {
                  // Use the address for mapping since we don't have coordinates
                  MapsLauncher.launchQuery(address);
                },
              ),
            ),
            if (phoneNumber.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phoneNumber),
                subtitle: const Text('Contact Number'),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                    launchUrl(phoneUri);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final id = _orderDetails['order_id'] ?? _orderDetails['id'] ?? 'N/A';
    final status = _orderDetails['status'] ?? 'Unknown';
    final date = _orderDetails['created_at'] ?? 'Unknown date';
    final totalAmount = _parseDouble(_orderDetails['total_amount']);
    final restaurantName = _orderDetails['restaurant_name'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(status),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Order ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(id.toString()),
            ),
            ListTile(
              title: const Text(
                'Restaurant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(restaurantName),
            ),
            ListTile(
              title: const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_formatDate(date.toString())),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Total Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹ ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = _orderDetails['items'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            items.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No items found'),
                  ),
                )
                : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item['product_name'] ?? 'Unknown product';
                    final quantity = item['quantity'] ?? 0;
                    final price = _parseDouble(item['price']);
                    final totalPrice = _parseDouble(item['total_price']);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$quantity x ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹ ${totalPrice.toStringAsFixed(2)}'),
                                Text(
                                  '₹ ${price.toStringAsFixed(2)} each',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingSection() {
    final status = _orderDetails['status'] ?? 'unknown';

    // Define tracking steps
    final List<Map<String, dynamic>> trackingSteps = [
      {'status': 'pending', 'title': 'Order Placed', 'icon': Icons.receipt},
      {'status': 'preparing', 'title': 'Preparing', 'icon': Icons.shopping_bag},
      {
        'status': 'out_for_delivery',
        'title': 'Out for Delivery',
        'icon': Icons.local_shipping,
      },
      {'status': 'delivered', 'title': 'Delivered', 'icon': Icons.check_circle},
    ];

    // Determine current step
    int currentStep = 0;
    for (int i = 0; i < trackingSteps.length; i++) {
      if (trackingSteps[i]['status'] == status.toLowerCase()) {
        currentStep = i;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Tracking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            status.toLowerCase() == 'cancelled'
                ? Center(
                  child: Column(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Order Cancelled',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
                : Stepper(
                  currentStep: currentStep,
                  controlsBuilder: (context, details) {
                    return const SizedBox.shrink(); // Hide the controls
                  },
                  steps:
                      trackingSteps.map((step) {
                        final isActive =
                            trackingSteps.indexOf(step) <= currentStep;
                        return Step(
                          title: Text(step['title']),
                          content: const SizedBox.shrink(),
                          isActive: isActive,
                          state:
                              isActive
                                  ? trackingSteps.indexOf(step) < currentStep
                                      ? StepState.complete
                                      : StepState.indexed
                                  : StepState.disabled,
                          // icon: Icon(step['icon']),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load order details',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadOrderDetails,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadOrderDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSummary(),
                      _buildTrackingSection(),
                      _buildOrderItems(),
                      _buildDeliverySection(),
                    ],
                  ),
                ),
              ),
    );
  }
}
