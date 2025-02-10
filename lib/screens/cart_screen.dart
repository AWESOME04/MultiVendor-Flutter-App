import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../services/payment_service.dart';
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
      setState(() => _isLoading = true);

      final cartService =
          CartService(Provider.of<UserService>(context, listen: false));
      final cartData = await cartService.getCart();

      if (!mounted) return;

      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        _total = cartData['total']?.toDouble() ?? 0.0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      if (!userService.isAuthenticated || userService.email == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final success = await PaystackService.processPayment(
        context: context,
        email: userService.email!,
        amount: _total,
        phone: _phoneController.text,
        onSuccess: () async {
          // Process order
          final cartService = CartService(userService);
          await cartService.checkout(_phoneController.text);

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
        },
        onCancel: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled')),
          );
        },
      );

      if (!success) {
        throw 'Payment failed';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      setState(() => _isLoading = true);

      final cartService =
          CartService(Provider.of<UserService>(context, listen: false));
      await cartService.updateCartQuantity(
        productId: productId,
        quantity: newQuantity,
      );

      // Update local state immediately
      final itemIndex =
          _cartItems.indexWhere((item) => item['productId'] == productId);
      if (itemIndex != -1) {
        setState(() {
          _cartItems[itemIndex]['quantity'] = newQuantity;
          // Recalculate total
          _total = _cartItems.fold(0,
              (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: ${e.toString()}')),
      );
      // Reload cart to ensure consistency
      await _loadCart();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildQuantityControls(Map<String, dynamic> item) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: item['quantity'] > 1
              ? () => _updateQuantity(item['productId'], item['quantity'] - 1)
              : null,
        ),
        Text('${item['quantity']}'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () =>
              _updateQuantity(item['productId'], item['quantity'] + 1),
        ),
      ],
    );
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
                  onRemove: (productId) async {
                    try {
                      final cartService = CartService(
                          Provider.of<UserService>(context, listen: false));
                      await cartService.removeFromCart(productId);
                      _loadCart(); // Refresh cart after removal
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  onQuantityChange: (productId, quantity) async {
                    await _updateQuantity(productId, quantity);
                  },
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
