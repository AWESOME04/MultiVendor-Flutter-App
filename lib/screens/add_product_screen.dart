import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import '../config/config.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Electronics';
  bool _isLoading = false;
  XFile? _imageFile;
  Uint8List? _webImage;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();

  final List<String> _categories = [
    'Electronics',
    'Fashion',
    'Home',
    'Beauty',
    'Sports',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      if (kIsWeb) {
        // Handle web image preview
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final uri = Uri.parse(Config.cloudinaryUploadUrl);
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = await Config.generateSignature(timestamp, 'products');

      if (kIsWeb) {
        final bytes = await _imageFile!.readAsBytes();
        var request = http.MultipartRequest('POST', uri);

        // Add file first, just like in React
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // Must be 'file'
            bytes,
            filename: _imageFile!.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        // Add fields in the same order as React
        request.fields.addAll({
          'upload_preset': Config.cloudinaryUploadPreset,
          'folder': 'products',
          'cloud_name': Config.cloudinaryCloudName,
          'api_key': Config.cloudinaryApiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        });

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('Upload response status: ${response.statusCode}');
        print('Upload response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          return data['secure_url'];
        } else {
          throw 'Failed to upload image: ${response.statusCode}';
        }
      } else {
        // Mobile implementation remains similar but follows same order
        final request = http.MultipartRequest('POST', uri);

        // Add file first
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _imageFile!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        // Add fields in same order as web
        request.fields.addAll({
          'upload_preset': Config.cloudinaryUploadPreset,
          'folder': 'products',
          'cloud_name': Config.cloudinaryCloudName,
          'api_key': Config.cloudinaryApiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        });

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          return data['secure_url'];
        } else {
          throw 'Failed to upload image: ${response.statusCode}';
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      rethrow;
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      String? imageUrl;

      if (_imageFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );
        imageUrl = await _uploadImage();

        if (imageUrl == null) {
          throw 'Failed to upload image';
        }
      }

      final productData = {
        'name': _nameController.text,
        'desc': _descController.text,
        'type': _selectedCategory,
        'stock': int.parse(_stockController.text),
        'price': double.parse(_priceController.text),
        'img': imageUrl ?? '',
        'available': true,
        'seller': userService.userId,
      };

      print('Submitting product data: $productData');

      final response = await http.post(
        Uri.parse('https://product-service-qwti.onrender.com/product/create'),
        headers: {
          'Authorization': 'Bearer ${userService.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(productData),
      );

      print(
          'Product creation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Failed to add product';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: _buildImagePreview(),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(
                      _imageFile != null ? 'Change Image' : 'Select Image'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stock quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isLoading ? 'Adding...' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return _buildImagePicker();
    }

    if (kIsWeb && _webImage != null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: MemoryImage(_webImage!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // For mobile platforms
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(_imageFile!.path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add product image',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'or use button below',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
