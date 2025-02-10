import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/cart_service.dart';
import '../services/cart_notifier.dart';

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
  bool _isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
  }

  Future<void> _checkIfInCart() async {
    final cartService =
        CartService(Provider.of<UserService>(context, listen: false));
    final isInCart = await cartService.isProductInCart(widget.productId);
    setState(() {
      _isInCart = isInCart;
    });
  }

  Future<void> _addToCart(CartService cartService) async {
    if (_isInCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item is already in your cart')),
      );
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      await cartService.addToCart(
        productId: widget.productId,
        name: widget.title,
        price: widget.price.toDouble(),
        image: widget.imageUrl,
      );

      Provider.of<CartNotifier>(context, listen: false).updateCount(
          (Provider.of<CartNotifier>(context, listen: false).cartItemCount +
              1));

      setState(() => _isInCart = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isAddingToCart = false);
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
