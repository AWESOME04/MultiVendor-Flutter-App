import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/cart_item.dart';
import '../widgets/empty_cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  double _total = 0;
  final _phoneController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    // Wait for user service to initialize
    final userService = Provider.of<UserService>(context, listen: false);
    while (!userService.isInitialized) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    if (!userService.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    _loadCart();
  }

  Future<void> _loadCart() async {
    if (!mounted) return;

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final cartService = CartService(userService);
      final cartData = await cartService.getCart();

      if (!mounted) return;

      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        _total = (cartData['total'] ?? 0).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cart: $e');
      if (!mounted) return;

      if (e.toString().contains('User not authenticated')) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cart: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isCheckingOut = true);
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      if (!userService.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final cartService = CartService(userService);
      await cartService.checkout(_phoneController.text);

      // Clear cart after successful checkout
      setState(() {
        _cartItems = [];
        _total = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Checkout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to checkout: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cartItems.isEmpty) {
      return const Scaffold(
        body: EmptyCart(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return CartItem(
                  item: item,
                  onQuantityChanged: _loadCart,
                  onRemoved: _loadCart,
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: \$${_total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCheckingOut ? null : _handleCheckout,
                    child: _isCheckingOut
                        ? const CircularProgressIndicator()
                        : const Text('Checkout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
