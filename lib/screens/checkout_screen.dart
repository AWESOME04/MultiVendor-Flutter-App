import 'package:flutter/material.dart';
import 'address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Card';
  final TextEditingController _promoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Address Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Change',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Home',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '925 S Chugach St #APT 10, Alaska 99645',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method Section
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildPaymentOption('Card', Icons.credit_card),
                  const SizedBox(width: 12),
                  _buildPaymentOption('Cash', Icons.attach_money),
                  const SizedBox(width: 12),
                  _buildPaymentOption('Apple Pay', Icons.apple),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedPaymentMethod == 'Card')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/visa.png',
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '**** **** **** 2512',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Order Summary Section
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Sub-total', '5,870'),
              _buildSummaryRow('VAT (%)', '0.00'),
              _buildSummaryRow('Shipping fee', '80'),
              const Divider(height: 32),
              _buildSummaryRow('Total', '5,950', isTotal: true),
              const SizedBox(height: 16),

              // Promo Code Section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$$amount',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
}
