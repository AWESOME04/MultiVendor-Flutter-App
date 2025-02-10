import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

class CartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(String) onRemove;
  final Function(String, int) onQuantityChange;

  const CartItem({
    Key? key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChange,
  }) : super(key: key);

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text(
              'Are you sure you want to remove ${item['name']} from your cart?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onRemove(item['productId']);
              },
            ),
          ],
        );
      },
    );
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
                        onPressed: (item['quantity'] ?? 0) > 1
                            ? () => onQuantityChange(
                                item['productId'], (item['quantity'] ?? 0) - 1)
                            : null,
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey;
                              }
                              return Colors.black;
                            },
                          ),
                        ),
                      ),
                      Text('${item['quantity'] ?? 0}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => onQuantityChange(
                            item['productId'], (item['quantity'] ?? 0) + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
