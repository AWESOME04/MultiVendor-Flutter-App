import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_product_screen.dart';
import '../widgets/edit_product_modal.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerProducts() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);

      print('Current user ID: ${userService.userId}'); // Debug log

      final response = await http.get(
        Uri.parse('https://product-service-qwti.onrender.com/'),
        headers: {
          'Authorization': 'Bearer ${userService.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final allProducts = data['products'] ?? data['data']?['products'] ?? [];

        print('All products: $allProducts'); // Debug log

        // Filter products for the current seller
        final sellerProducts = allProducts.where((product) {
          print(
              'Comparing product seller: ${product['seller']} with user ID: ${userService.userId}'); // Debug log
          print(
              'Types - product seller: ${product['seller'].runtimeType}, user ID: ${userService.userId.runtimeType}'); // Debug type check
          return product['seller'].toString() ==
              userService.userId
                  .toString(); // Convert both to strings for comparison
        }).toList();

        print('Filtered seller products: $sellerProducts'); // Debug log

        if (mounted) {
          setState(() {
            _products = sellerProducts;
            _isLoading = false;
          });
        }
      } else {
        throw 'Failed to load products: ${response.statusCode}';
      }
    } catch (e) {
      print('Error fetching seller products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load your products: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);

      final response = await http.delete(
        Uri.parse(
            'https://product-service-qwti.onrender.com/product/$productId'),
        headers: {
          'Authorization': 'Bearer ${userService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
          setState(() {
            _products.removeWhere((product) => product['id'] == productId);
          });
        }
      } else {
        throw 'Failed to delete product: ${response.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> product) async {
    final productId = product['id'] ?? product['_id'];
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Product ID is missing')),
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete ${product['name']}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(productId.toString());
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProduct(Map<String, dynamic> updatedProduct) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final productId = updatedProduct['id'] ?? updatedProduct['_id'];

      if (productId == null) {
        throw 'Product ID is missing';
      }

      final response = await http.put(
        Uri.parse(
            'https://product-service-qwti.onrender.com/product/$productId'),
        headers: {
          'Authorization': 'Bearer ${userService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': updatedProduct['name'],
          'desc': updatedProduct['desc'],
          'price': updatedProduct['price'],
          'stock': updatedProduct['stock'],
          'available': updatedProduct['available'],
          'type': updatedProduct['type'], // Add type if needed
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          // Update local state
          final updatedProducts = _products.map((product) {
            if (product['id'] == productId || product['_id'] == productId) {
              return {...product, ...updatedProduct};
            }
            return product;
          }).toList();

          setState(() {
            _products = updatedProducts;
          });
        }
      } else {
        throw 'Failed to update product: ${response.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e')),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
              _fetchSellerProducts(); // Refresh list after adding new product
            },
          ),
        ],
      ),
      body: _products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "You haven't posted any products yet",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      );
                      _fetchSellerProducts();
                    },
                    child: const Text('Add Your First Product'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          product['img'] ?? 'https://placehold.co/600x400',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'No name',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product['desc'] ?? 'No description',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${product['price']?.toString() ?? '0'}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Stock: ${product['stock']?.toString() ?? '0'}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product['available'] == true
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product['available'] == true
                                        ? 'Available'
                                        : 'Out of Stock',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditProductModal(
                                        product: product,
                                        onSubmit: _updateProduct,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _showDeleteConfirmation(product),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
