
import 'package:dbz/c22heckout.dart';
import 'package:flutter/material.dart';
import 'package:dbz/services/uapiserive.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen55 extends StatefulWidget {
  const CartScreen55({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen55> {
  bool isLoading = true;
  Map<String, dynamic> cartData = {};
  List<dynamic> cartItems = [];
  String? errorMessage;

  double totalAmount = 0.0;
  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getCart();
      setState(() {
        cartData = data;
        cartItems = data['items'] ?? [];
        // Properly parse the total amount from API
        totalAmount =
            double.tryParse(data['total_amount']?.toString() ?? '0.0') ?? 0.0;

        // If API doesn't provide reliable total, calculate it manually
        if (totalAmount == 0.0 && cartItems.isNotEmpty) {
          totalAmount = _calculateTotalAmount();
        }

        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to load cart: ${error.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _updateCartItem(int itemId, int quantity) async {
    if (quantity <= 0) {
      _removeCartItem(itemId);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.updateCartItem(itemId: itemId, quantity: quantity);
      _fetchCart();
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to update item: ${error.toString()}';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update item: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeCartItem(int itemId) async {
    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.removeFromCart(itemId);
      _fetchCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to remove item: ${error.toString()}';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCheckoutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(totalamount: totalAmount),
        // CheckoutPage(
        //   totalAmount: totalAmount,
        //   cartItems: cartItems.cast<Map<String, dynamic>>(),
        // ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearCartDialog,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? _buildErrorView()
              : cartItems.isEmpty
              ? _buildEmptyCartView()
              : _buildCartItemsList(),
      bottomNavigationBar: cartItems.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your cart to place an order',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Browse Items',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchCart, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    return RefreshIndicator(
      onRefresh: _fetchCart,
      child: ListView.builder(
        itemCount: cartItems.length,
        padding: const EdgeInsets.only(bottom: 100),
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return _buildCartItem(item);
        },
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final product = item['product'] ?? {};
    final name = product['name'] ?? 'Product';
    final quantity = item['quantity'] ?? 1;
    final itemId = item['id'] ?? 0;
    final productId = product['id'] ?? 0;
    final notes = product['description'] ?? '';

    // Convert price string to double
    final priceStr = product['price'] ?? '0.00';
    final price = double.tryParse(priceStr) ?? 0.0;

    final totalPrice = price * quantity;

    final imagePath = product['image'] ?? '';
    final restaurantName = product['restaurant_name'] ?? '';

    // Construct the full image URL
    final imageUrl =
        imagePath.isNotEmpty ? '${ApiService.baseUrl}$imagePath' : '';

    return Dismissible(
      key: Key('cart_item_$itemId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _removeCartItem(itemId);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood),
                              ),
                        )
                        : Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood),
                        ),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurantName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: $notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(2)} x $quantity',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [_buildQuantityControl(itemId, quantity)],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(int itemId, int quantity) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _updateCartItem(itemId, quantity - 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: () => _updateCartItem(itemId, quantity + 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var item in cartItems) {
      final product = item['product'] ?? {};
      final priceStr = product['price'] ?? '0.00';
      final price = double.tryParse(priceStr) ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      total += (price * quantity);
    }
    return total;
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCheckoutPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text(
              'Are you sure you want to remove all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearCart();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  Future<void> _clearCart() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Assuming there's no direct API to clear cart, remove items one by one
      for (var item in cartItems) {
        await ApiService.removeFromCart(item['id']);
      }
      _fetchCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart cleared'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to clear cart: ${error.toString()}';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cart: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
