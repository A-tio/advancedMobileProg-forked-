import 'dart:io';

import 'package:firebase_nexus/helpers/adminPageSupabaseHelper.dart';
import 'package:firebase_nexus/helpers/local_database_helper.dart';
import 'package:firebase_nexus/models/supabaseProduct.dart';
import 'package:flutter/material.dart';

class UserViewProductPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const UserViewProductPage({Key? key, required this.productData})
      : super(key: key);

  @override
  State<UserViewProductPage> createState() => _UserViewProductPageState();
}

class _UserViewProductPageState extends State<UserViewProductPage> {
  Map<String, dynamic>? _selectedVariation;
  final _quantityController = TextEditingController();
  SQLFliteDatabaseHelper sqlFliteDatabaseHelper = SQLFliteDatabaseHelper();
  // late SupabaseProduct supaprod;
  late File? file;

  @override
  void initState() {
    super.initState();
    print('widget.productData');
    print(widget.productData);
    setState(() {
      _quantityController.text = '1';
    });
    // sqlFliteDatabaseHelper.resetDatabase();
    // _getFile();j
  }

  // void _getFile() async {
  //   try {
  //     File? fetched = await fileFromSupabase(widget.productData['img']);
  //     setState(() {
  //       file = fetched;
  //     });
  //   } catch (e) {
  //     print("Error $e");
  //   }
  // }

  void _storeToCart() async {
    final quant = int.tryParse(_quantityController.text) ?? 1;
    final name = widget.productData['name'];
    final variationName = _selectedVariation?["name"] ?? '';
    final product = SupabaseProduct(
      prodId: widget.productData['id'],
      name: name,
      included: true,
      category: widget.productData['category_name'],
      quantity: quant,
      variation: _selectedVariation!['name'],
      price: _selectedVariation!['price'],
      img: widget.productData['img'],
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

  void _adjustQuantity(int delta) {
    final rawStock = widget.productData['stock'];
    final stock = rawStock is int ? rawStock : int.tryParse('$rawStock') ?? 0;
    if (stock <= 0) {
      setState(() => _quantityController.text = '0');
      return;
    }
    final current = int.tryParse(_quantityController.text) ?? 1;
    final updated = (current + delta).clamp(1, stock).toInt();
    if (updated == current) {
      return;
    }
    setState(() => _quantityController.text = updated.toString());
  }

  @override
  Widget build(BuildContext context) {
    final productData = widget.productData;
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
                        children: [
                          Expanded(
                            child: Text(
                              productData['name'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B2E19),
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedVariation != null
                                      ? '₱${_selectedVariation!['price']}'
                                      : '₱${productData['lowest_price'] ?? '--'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B2E19),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () => _adjustQuantity(1),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE27D19),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      controller: _quantityController,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF4B2E19),
                                          ),
                                        ),
                                        suffixText:
                                            '/ ${productData['stock']}',
                                      ),
                                      onChanged: (val) {
                                        final value = int.tryParse(val) ?? 0;
                                        if (value >
                                            (productData['stock'] ?? 0)) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Quantity exceeds available stock.'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () => _adjustQuantity(-1),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE27D19),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE27D19),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _selectedVariation == null
                                ? null
                                : () async {
                                    final stock = productData['stock'] ?? 0;
                                    final inputText =
                                        _quantityController.text;
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
                        ),
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
