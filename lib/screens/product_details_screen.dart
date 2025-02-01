import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/cart_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final int price;
  final String productId;
  final int? discount;

  const ProductDetailsScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.productId,
    this.discount,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isAddingToCart = false;

  Future<void> _addToCart(CartService cartService) async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      print('Adding product to cart:');
      print('- Product ID: ${widget.productId}');
      print('- Title: ${widget.title}');
      print('- Price: ${widget.price}');
      print('- Image: ${widget.imageUrl}');

      await cartService.addToCart(
        productId: widget.productId,
        name: widget.title,
        price: widget.price.toDouble(),
        image: widget.imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in _addToCart: $e');
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('starting up')) {
          errorMessage =
              'Server is starting up. Please wait a moment and try again.';
        } else if (e.toString().contains('Network error') ||
            e.toString().contains('Failed to connect')) {
          errorMessage =
              'Cannot connect to server. Please check your connection.';
        } else if (e.toString().contains('timed out')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('Authentication failed')) {
          errorMessage = 'Please log in again to continue.';
        } else {
          errorMessage = 'Failed to add to cart: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: e.toString().contains('Authentication failed')
                ? SnackBarAction(
                    label: 'Login',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  )
                : e.toString().contains('starting up')
                    ? SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () => _addToCart(cartService),
                      )
                    : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final cartService = CartService(userService);
    final isBuyer = userService.isBuyer;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
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
      body: SafeArea(
        child: Column(
          children: [
            // Product Image with Favorite Button
            Stack(
              children: [
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Image.network(
                    widget.imageUrl.isEmpty
                        ? 'https://placehold.co/600x600/png'
                        : widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 50,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isBuyer) // Only show favorite button for buyers
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The name says it all, the right size slightly snugs the body leaving enough room for comfort in the sleeves and waist.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    // Bottom Price and Add to Cart
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '\$${widget.price}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        if (isBuyer) // Only show Add to Cart button for buyers
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isAddingToCart
                                  ? null
                                  : () => _addToCart(cartService),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isAddingToCart
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isAddingToCart ? 'Adding...' : 'Add to Cart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
