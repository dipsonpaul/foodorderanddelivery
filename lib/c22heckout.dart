import 'package:dbz/ordersucces.dart';
import 'package:dbz/services/uapiserive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final double totalamount;

  const CheckoutPage({super.key, required this.totalamount});
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String _selectedPaymentMethod = 'cash_on_delivery';
  LatLng? selectedLocation;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    notesController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _startRazorpayPayment() {
    int amountInPaisa = (widget.totalamount * 100).toInt();
    var options = {
      'key': 'rzp_test_YkCy6jA2GFlk5F',
      'amount': amountInPaisa, // Amount in paisa (e.g. 10000 = 100 INR)
      'name': 'DBZ BOYZ',
      'description': 'Order Payment',
      'prefill': {'contact': phoneController.text, 'email': 'test@example.com'},
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _submitCheckout();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitCheckout() async {
    if (addressController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isLoggedIn = await ApiService.isLoggedIn();
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ApiService.checkout(
        address: addressController.text,
        phoneNumber: phoneController.text.toString(),
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        paymentMethod: _selectedPaymentMethod,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderSuccessPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your full address',
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Phone Number',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your phone number',
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Order Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Any special instructions',
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Select Delivery Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 200, child: _buildFlutterMap()),

              const SizedBox(height: 20),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildPaymentMethodSelector(),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${widget.totalamount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedPaymentMethod == 'online_payment') {
                      _startRazorpayPayment();
                    } else {
                      _submitCheckout();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Place Order',
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
      ),
    );
  }

  Widget _buildFlutterMap() {
    return selectedLocation == null
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
          options: MapOptions(
            initialCenter: selectedLocation!,
            initialZoom: 15,
            onTap: (_, latLng) {
              setState(() {
                selectedLocation = latLng;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: selectedLocation!,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Cash on Delivery'),
          value: 'cash_on_delivery',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ),
        RadioListTile<String>(
          title: const Text('Online Payment'),
          value: 'online_payment',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ),
      ],
    );
  }
}
