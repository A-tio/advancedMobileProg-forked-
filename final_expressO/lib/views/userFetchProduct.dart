import 'dart:io';

import 'package:firebase_nexus/helpers/adminPageSupabaseHelper.dart';
import 'package:firebase_nexus/helpers/local_database_helper.dart';
import 'package:firebase_nexus/helpers/userPageSupabaseHelper.dart';
import 'package:firebase_nexus/models/supabaseProduct.dart';
import 'package:firebase_nexus/widgets/loading_screens.dart';
import 'package:flutter/material.dart';

class UserFetchProductPage extends StatefulWidget {
  final int prodID;
  const UserFetchProductPage({super.key, required this.prodID});

  @override
  State<UserFetchProductPage> createState() => _UserFetchProductPageState();
}

class _UserFetchProductPageState extends State<UserFetchProductPage> {
  Map<String, dynamic>? _selectedVariation;
  late Map<String, dynamic> productData;
  bool _loading = true;
  final _quantityController = TextEditingController();
  SQLFliteDatabaseHelper sqlFliteDatabaseHelper = SQLFliteDatabaseHelper();
  UserSupabaseHelper userSupabaseHelper = UserSupabaseHelper();
  // late SupabaseProduct supaprod;
  late File? file;

  @override
  void initState() {
    super.initState();
    setState(() {
      _quantityController.text = '1';
    });
    _loadInitialData();
    // sqlFliteDatabaseHelper.resetDatabase();
    // _getFile();j
  }

  Future<void> _loadInitialData() async {
    try {
      print('Fetching product with ID: ${widget.prodID}');
      final fetchedProduct =
          await userSupabaseHelper.getProductbyId(widget.prodID);

      if (fetchedProduct == null) {
        throw Exception('Product not found');
      }

      // Normalize the fetched product data
      final name = fetchedProduct['name'] ?? 'Unknown';
      final variations = fetchedProduct['variations'] ?? [];
      final price = fetchedProduct['lowest_price']?.toString() ?? 'N/A';
      final imageUrl =
          fetchedProduct['img'] ?? 'https://placehold.co/200x150/png';

      setState(() {
        productData = {
          'id': fetchedProduct['id'],
          'name': name,
          'lowest_price': fetchedProduct['lowest_price'],
          'img': imageUrl,
          'status': fetchedProduct['status'],
          'desc': fetchedProduct['desc'],
          'category_name': fetchedProduct['category_name'],
          'stock': fetchedProduct['stock'],
          'variations': variations,
        };
        _loading = false;
      });

      print('Product loaded successfully!');
      print(productData);
    } catch (e, stack) {
      print("Error loading product: $e");
      print(stack);
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load product. Please try again later.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _storeToCart() async {
    final quant = int.tryParse(_quantityController.text) ?? 1;
    final name = productData['name'];
    final variationName = _selectedVariation?["name"] ?? '';
    final product = SupabaseProduct(
      prodId: productData['id'],
      name: name,
      included: true,
      category: productData['category_name'],
      quantity: quant,
      variation: _selectedVariation!['name'],
      price: _selectedVariation!['price'],
      img: productData['img'],
    );

    final result = await sqlFliteDatabaseHelper.insertCart('cart', product);
    final isSuccess = result['success'] == true;

    _showSnackBar(
      icon: isSuccess ? Icons.check : Icons.error,
      iconColor: isSuccess ? const Color(0xFFE27D19) : Colors.red,
      message: isSuccess
          ? '$quant $variationName $name${quant > 1 ? 's' : ''} added to cart!'
          : 'There was a problem on our end, please try again later!',
    );
  }

  void _showSnackBar({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LoadingScreens(
        message: 'Loading...',
        error: false,
        onRetry: null,
      );
    }

    final variations = (productData['variations'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38241D), // brown background
        elevation: 0, // optional: remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'View Product',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // white text
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF9F6ED),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  productData['img'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.coffee,
                          size: 80, color: Color(0xFF4B2E19)),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Product Details
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and Status Row

                      // Product Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productData['name'] as String,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B2E19),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFF8F6F0), // light beige background
                              borderRadius: BorderRadius.circular(
                                  50), // 👈 makes it pill-shaped
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF9E8E57).withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              productData['category_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    Color(0xFF9E8E57), // muted gold-brown text
                                fontFamily: 'Quicksand',
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Description
                      Text(
                        productData['desc'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        height: 1,
                        color: const Color(0xFF4B2E19).withOpacity(0.2),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),

                      // Stock + Variations
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Variations as Chips
                          const Text(
                            'Size',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B2E19),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            children: variations.map((v) {
                              final isSelected =
                                  _selectedVariation?['name'] == v['name'];
                              return ChoiceChip(
                                label: Text(v['name']),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedVariation = selected
                                        ? v
                                        : null; // store full object
                                  });
                                },
                                selectedColor: const Color(0xFF4B2E19),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF4B2E19),
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor:
                                    const Color(0xFF4B2E19).withOpacity(0.05),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B2E19),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedVariation != null
                                    ? '₱${_selectedVariation!['price']}'
                                    : '₱${productData['lowest_price'] ?? '--'}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B2E19),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

// Quantity Input + Add to Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity Input
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF4B2E19)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF4B2E19)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixText: '/ ${productData['stock']}',
                              ),
                              onChanged: (val) {
                                final value = int.tryParse(val) ?? 0;
                                if (value > (productData['stock'] ?? 0)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Quantity exceeds available stock.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              controller: _quantityController,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Add to Cart Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE27D19),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _selectedVariation == null
                                ? null
                                : () async {
                                    final stock = productData['stock'] ?? 0;
                                    final inputText = _quantityController.text;
                                    final inputQuantity =
                                        int.tryParse(inputText) ?? 0;
                                    final name =
                                        productData['name'] ?? 'Product';

                                    print(inputQuantity);
                                    print(inputText);

                                    if (inputQuantity <= 0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please enter a valid quantity.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    if (inputQuantity > stock) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Not enough stock available.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    // TODO: Insert your add-to-cart logic here
                                    // e.g. LocalDatabaseHelper.addToCart(productData, inputQuantity);
                                    _storeToCart();

                                    setState(() {
                                      _quantityController.text = '1';
                                    });
                                  },
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
