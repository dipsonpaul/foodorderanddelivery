import 'package:dbz/services/uapiserive.dart';
import 'package:dbz/orderdetails.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersPage extends StatefulWidget {
  final String userRole;

  const OrdersPage({
    Key? key,
    this.userRole = 'user', // Default to user role
  }) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final List<dynamic> _orders = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  String? _selectedStatus;
  final ScrollController _scrollController = ScrollController();
  late List<Map<String, dynamic>> _statusOptions;

  @override
  void initState() {
    super.initState();
    // Get status options based on the user's role
    _statusOptions = OrderStatus.getStatusOptionsForRole(widget.userRole);
    _loadOrders();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });

    try {
      final orders = await ApiService.getOrders(
        status: _selectedStatus,
        page: _page,
        pageSize: 10,
      );

      setState(() {
        _orders.clear();
        _orders.addAll(orders);
        _isLoading = false;
        _hasMore =
            orders.length == 10; // Assume there are more if we got 10 items
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load orders: $e');
    }
  }

  Future<void> _loadMoreOrders() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      _page++;
    });

    try {
      final moreOrders = await ApiService.getOrders(
        status: _selectedStatus,
        page: _page,
        pageSize: 10,
      );

      setState(() {
        _orders.addAll(moreOrders);
        _isLoading = false;
        _hasMore = moreOrders.length == 10;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _page--;
      });
      _showErrorSnackBar('Failed to load more orders: $e');
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

  void _refreshOrders() {
    _loadOrders();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
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

  // Helper to determine if current user can cancel this order
  bool _canCancelOrder(String status) {
    if (widget.userRole != 'user') return false;
    return status.toLowerCase() == OrderStatus.pending;
  }

  Future<void> _cancelOrder(String orderId) async {
    // Show confirmation dialog
    final shouldCancel =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Cancel Order'),
                content: const Text(
                  'Are you sure you want to cancel this order?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
        ) ??
        false;

    if (!shouldCancel) return;

    try {
      setState(() => _isLoading = true);
      // await ApiService.updateCartItem(orderId, OrderStatus.cancelled);
      _refreshOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('My Orders'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          Expanded(
            child:
                _isLoading && _orders.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _orders.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _refreshOrders,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async {
                        _refreshOrders();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _orders.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _orders.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final order = _orders[index];
                          final id = order['id'] ?? order['order_id'] ?? 'N/A';
                          final status = order['status'] ?? 'Unknown';
                          final date =
                              order['created_at'] ??
                              order['order_date'] ??
                              'Unknown date';
                          final total = _parseDouble(order['total_amount']);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            OrderDetailsPage(orderId: id),
                                  ),
                                ).then((_) => _refreshOrders());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Order #$id',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            OrderStatus.labels[status] ??
                                                status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              OrderStatus.getStatusColor(
                                                status,
                                              ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(date.toString()),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '\$${total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        OrderDetailsPage(
                                                          orderId: id,
                                                        ),
                                              ),
                                            ).then((_) => _refreshOrders());
                                          },
                                          child: const Text('View Details'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// Constants for Order Status
class OrderStatus {
  // Status values used in the database
  static const String pending = 'pending';
  static const String preparing = 'preparing';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  // Display labels for statuses
  static const Map<String, String> labels = {
    pending: 'Pending',
    preparing: 'Preparing',
    outForDelivery: 'Out for Delivery',
    delivered: 'Delivered',
    cancelled: 'Cancelled',
  };

  // Status options for different user types
  static List<Map<String, dynamic>> getStatusOptionsForRole(String role) {
    switch (role) {
      case 'user':
        return [
          {'value': null, 'label': 'All Orders'},
          {'value': pending, 'label': labels[pending]!},
          {'value': preparing, 'label': labels[preparing]!},
          {'value': outForDelivery, 'label': labels[outForDelivery]!},
          {'value': delivered, 'label': labels[delivered]!},
          {'value': cancelled, 'label': labels[cancelled]!},
        ];
      case 'delivery':
        return [
          {'value': outForDelivery, 'label': labels[outForDelivery]!},
        ];
      case 'admin':
        return [
          {'value': null, 'label': 'All Orders'},
          {'value': pending, 'label': labels[pending]!},
          {'value': preparing, 'label': labels[preparing]!},
          {'value': outForDelivery, 'label': labels[outForDelivery]!},
          {'value': delivered, 'label': labels[delivered]!},
          {'value': cancelled, 'label': labels[cancelled]!},
        ];
      default:
        return [
          {'value': null, 'label': 'All Orders'},
        ];
    }
  }

  // Available status transitions based on role
  static List<String> getAvailableTransitionsForRole(
    String currentStatus,
    String role,
  ) {
    switch (role) {
      case 'user':
        // Users can only cancel pending orders
        if (currentStatus == pending) {
          return [cancelled];
        }
        return [];
      case 'delivery':
        // Delivery people can only mark orders as delivered
        if (currentStatus == outForDelivery) {
          return [delivered];
        }
        return [];
      case 'admin':
        // Admins can transition to any status
        switch (currentStatus) {
          case pending:
            return [preparing, cancelled];
          case preparing:
            return [outForDelivery, cancelled];
          case outForDelivery:
            return [delivered, cancelled];
          case delivered:
            return [];
          case cancelled:
            return [];
          default:
            return [];
        }
      default:
        return [];
    }
  }

  // Get the color associated with a status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case pending:
        return Colors.orange;
      case preparing:
        return Colors.blue;
      case outForDelivery:
        return Colors.purple;
      case delivered:
        return Colors.green;
      case cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
