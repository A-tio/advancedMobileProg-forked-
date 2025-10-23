import 'dart:math';

import 'package:firebase_nexus/appColors.dart';
import 'package:firebase_nexus/helpers/userPageSupabaseHelper.dart';
import 'package:firebase_nexus/providers/navigation_provider.dart';
import 'package:firebase_nexus/providers/userProvider.dart';
import 'package:firebase_nexus/views/UserProducts.dart';
import 'package:firebase_nexus/views/userFetchProduct.dart';
import 'package:firebase_nexus/views/user_OrderPages/CartList.dart';
import 'package:firebase_nexus/widgets/loading_screens.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notifPage.dart';
import '../widgets/promo_carousel.dart';

final List<IconData> availableIcons = [
  Icons.fastfood,
  Icons.local_fire_department,
  Icons.local_bar,
  Icons.coffee,
  Icons.ramen_dining,
  Icons.set_meal,
  Icons.wine_bar,
  Icons.apple,
  Icons.local_drink,
  Icons.lunch_dining,
  Icons.bakery_dining,
  Icons.spa,
  Icons.icecream,
  Icons.rice_bowl,
];

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _loading = true;
  final supabaseHelper = UserSupabaseHelper();

  List<Map<String, dynamic>> promos = [];
  List<Map<String, dynamic>> _categs = [];
  List<Map<String, dynamic>> _bestsellers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser(context);
    try {
      print('STARTED');

      final discounts =
          await supabaseHelper.getAvailableDiscounts(userProvider.user!['id']);
      final topProducts = await supabaseHelper.getTopSales();
      final categs = await supabaseHelper.getCategs();
      print('discounts loaded!');
      print(discounts);
      print('top products loaded!');
      print(topProducts);

      List<Map<String, dynamic>> formatted = [];
      List<Map<String, dynamic>> bestSellers = [];
      List<Map<String, dynamic>> bestCats = [];

      // format discounts if present
      if (discounts.isNotEmpty) {
        formatted = formatDiscounts(discounts);
      }

      // set top 3 best sellers
      if (topProducts.isNotEmpty) {
        bestSellers = topProducts.take(3).toList();

        // collect unique categories from top products
        final seenCategories = <String>{};
        for (var p in topProducts) {
          if (!seenCategories.contains(p['category'])) {
            bestCats.add({
              "name": p['category'],
              "icon": p['cat_icon'],
            });
            seenCategories.add(p['category']);
          }
        }

        // fill remaining categories if we have fewer than 3
        for (var c in categs) {
          if (bestCats.length >= 3) break;
          if (!seenCategories.contains(c['name'])) {
            bestCats.add({
              "name": c['name'],
              "icon": c['icon'],
            });
            seenCategories.add(c['name']);
          }
        }
      }

      setState(() {
        _loading = false;
        promos = formatted;
        _bestsellers = bestSellers;
        _categs = bestCats.take(3).toList();
      });
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> formatDiscounts(
      List<Map<String, dynamic>> discounts) {
    return discounts.map((discount) {
      // Determine title based on type
      String title;
      if (discount['type'] == 'percentage') {
        title = '${discount['value']}% Discount!';
      } else {
        title = '₱${discount['value']} Off Your Order!';
      }

      // Compose subtitle (description + optional minimum spend info)
      String subtitle = discount['desc'] ?? '';
      if (discount['minimumSpend'] != null) {
        subtitle += (subtitle.isNotEmpty ? ' ' : '') +
            'Min spend ₱${discount['minimumSpend']}.';
      }

      // Optional: add expiry info
      if (discount['expiry_date'] != null) {
        final expiryDate = DateTime.parse(discount['expiry_date']).toLocal();
        final formattedDate =
            '${expiryDate.month}/${expiryDate.day}/${expiryDate.year}';
        subtitle += ' Valid until $formattedDate.';
      }

      return {
        'title': title,
        'subtitle': subtitle,
        'buttonText': discount['code'],
        'onTap': () {
          debugPrint('${discount['code']} clicked!');
        },
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);

    if (!userProvider.isLoaded || userProvider.user == null) {
      userProvider.loadUser(context);
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = userProvider.user;

    print(user);

// 🔶 LOADING OVERLAY
    if (_loading) {
      return LoadingScreens(
        message: 'Loading...',
        error: false,
        onRetry: null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF38241D),
        automaticallyImplyLeading: false,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              letterSpacing: -0.5,
              fontSize: 18,
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: "Hello, "),
              TextSpan(
                text: user!['username'],
                style: const TextStyle(
                  color: Color(0xFFE27D19),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Color.fromARGB(255, 255, 255, 255), size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0XFFFFFAED),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Optional padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                PromoCarousel(promos: promos),
                const SizedBox(height: 30),
                const Text(
                  'Bestsellers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1D17),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _bestsellers.take(3).map((item) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserFetchProductPage(
                                  prodID: item['product_id'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    item['product_img'],
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 50, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['product_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1D17),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // You can navigate or show a dialog here
                      },
                      child: const Text(
                        'See All →',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE27D19),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE27D19),
                          decorationThickness: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ..._categs.map((categ) {
                        final icon =
                            availableIcons[categ['icon']] ?? Icons.local_cafe;
                        return _buildCategoryBox(
                          categ['name'],
                          icon,
                          () {
                            navProvider.setCategory(categ['name']);
                            navProvider.setIndex(1);
                          },
                        );
                      }).toList(),
                      _buildCategoryBox('Others', Icons.more_horiz, () {
                        navProvider.setCategory('All');
                        navProvider.setIndex(1);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 55),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildCategoryBox(String label, IconData icon, VoidCallback onTap) {
  return Expanded(
    child: Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE27D19),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D1D17),
          ),
        ),
      ],
    ),
  );
}
