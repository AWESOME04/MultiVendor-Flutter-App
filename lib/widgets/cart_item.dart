import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

class CartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onQuantityChanged;
  final VoidCallback onRemoved;

  const CartItem({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemoved,
  });

  Future<void> _updateQuantity(BuildContext context, int change) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final cartService = CartService(userService);
      await cartService.updateQuantity(
        item['productId'],
        (item['quantity'] as int) + change,
      );
      onQuantityChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeItem(BuildContext context) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final cartService = CartService(userService);
      await cartService.removeFromCart(item['productId']);
      onRemoved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.network(
              item['image'] ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '\$${(item['price'] ?? 0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: item['quantity'] > 1
                            ? () => _updateQuantity(context, -1)
                            : null,
                      ),
                      Text('${item['quantity'] ?? 1}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _updateQuantity(context, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeItem(context),
            ),
          ],
        ),
      ),
    );
  }
}
