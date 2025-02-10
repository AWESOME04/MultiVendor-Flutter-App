import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import 'profile_screen.dart';
import 'my_products_screen.dart';
import 'add_product_screen.dart';
import 'auth_screen.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/cart_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  List<dynamic> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartCount();
    _checkNotificationPrompt();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final cartService = CartService(userService);
      final cartData = await cartService.getCart();

      if (!mounted) return;

      final cartNotifier = Provider.of<CartNotifier>(context, listen: false);
      cartNotifier.updateCount((cartData['items'] as List).length);
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  Future<void> _checkNotificationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownNotification = prefs.getBool('hasShownNotification') ?? false;

    if (!hasShownNotification && mounted) {
      await prefs.setBool('hasShownNotification', true);
      // Show notification dialog after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _showNotificationDialog();
      });
    }
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('"SHOP STOCK" Would Like To Send You Notifications'),
          content: const Text(
            'Notifications may include alerts, sounds, and icon badges. These can be configured in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Don\'t Allow'),
            ),
            TextButton(
              onPressed: () {
                // Handle notification permission
                Navigator.of(context).pop();
              },
              child: const Text(
                'Allow',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() {
    final userService = Provider.of<UserService>(context, listen: false);
    userService.clearUserData();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  List<Product> get filteredProducts {
    if (selectedCategory == 'All') {
      return _products;
    }
    return _products
        .where((product) => product.type == selectedCategory)
        .toList();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final productName = product.name.toString().toLowerCase();
          return productName.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, _) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            if (userService.isBuyer)
              Consumer<CartNotifier>(
                builder: (context, cartNotifier, child) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.pushNamed(context, '/cart')
                            .then((_) => _loadCartCount());
                      },
                    ),
                    if (cartNotifier.cartItemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartNotifier.cartItemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            if (userService.isSeller)
              IconButton(
                icon: const Icon(Icons.add_business),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddProductScreen()),
                  );
                },
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.person),
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                    break;
                  case 'cart':
                    if (userService.isBuyer) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartScreen()),
                      );
                    }
                    break;
                  case 'myProducts':
                    if (userService.isSeller) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyProductsScreen()),
                      );
                    }
                    break;
                  case 'addProduct':
                    if (userService.isSeller) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddProductScreen()),
                      );
                    }
                    break;
                  case 'logout':
                    _handleLogout();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                if (userService.isBuyer) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'cart',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined),
                          SizedBox(width: 8),
                          Text('Cart'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ];
                } else {
                  return [
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'myProducts',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined),
                          SizedBox(width: 8),
                          Text('My Products'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'addProduct',
                      child: Row(
                        children: [
                          Icon(Icons.add_box_outlined),
                          SizedBox(width: 8),
                          Text('Add Product'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ];
                }
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              if (userService.isSeller) ...[
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('My Products'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyProductsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_business),
                  title: const Text('Add Product'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddProductScreen()),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  _buildCategoryChip('Electronics'),
                  _buildCategoryChip('Fashion'),
                  _buildCategoryChip('Home'),
                  _buildCategoryChip('Beauty'),
                  _buildCategoryChip('Sports'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No products available'
                                : 'No products found',
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            selectedCategory = category;
          });
        },
        backgroundColor: isSelected ? Colors.black : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              title: product.name,
              imageUrl: product.img,
              price: product.price.toInt(),
              productId: product.id.toString(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  product.img.isEmpty
                      ? 'https://placehold.co/600x600/png'
                      : product.img,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.available ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.available
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                        if (product.stock > 0)
                          Text(
                            '${product.stock} left',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
