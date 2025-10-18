import 'dart:io';
import 'package:firebase_nexus/adminPages/AddProduct.dart';
import 'package:firebase_nexus/helpers/adminPageSupabaseHelper.dart';
import 'package:firebase_nexus/widgets/loading_overlay.dart';
import 'package:firebase_nexus/widgets/loading_screens.dart';
import 'package:flutter/material.dart';

class AddProductFlow extends StatefulWidget {
  const AddProductFlow({super.key});

  @override
  State<AddProductFlow> createState() => _AddProductFlowState();
}

class _AddProductFlowState extends State<AddProductFlow> {
  int _currentStep = 1;
  bool _loading = true;
  String? _error;
  bool _submitLoading = false;
  bool _initialized = false;
  bool _success = false;

  final supabaseHelper = AdminSupabaseHelper();

  // Shared draft state across steps
  Map<String, dynamic> productDraft = {
    "productName": "",
    "description": "",
    "productImage": null,
    "category": null,
    "stock": 0,
    "status": "Available",
    "variations": [],
    "final": false,
  };

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    print('INITIAL STATE METHOD');

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      if (_initialized) return;
      _initialized = true;

      final categories = await supabaseHelper.getAll("Categories",null,null);

      setState(() {
        if (categories.isNotEmpty) {
          productDraft["category"] = categories.first["id"].toString();
        }
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() => _loading = false);
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  void _updateDraft(Map<String, dynamic> updates) {
    setState(() {
      productDraft.addAll(updates);
    });
  }

  void _confirmSuccess() {
    setState(() {
      _success = true;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Product added successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushNamedAndRemoveUntil(context, '/products', (r) => false);
  }

  Future<void> _finalSubmit() async {
    try {
      print(
          '--------------------------------------------------------------------------------------------');

      final response = await supabaseHelper.insert('Products', {
        'cat_id': productDraft['category'],
        'name': productDraft['productName'],
        'desc': productDraft['description'],
        'stock': productDraft['stock'],
        'status': productDraft['status'],
        'variations': productDraft['variations'],
      });

      print(response);
      print(response['data']['id']);

      if (response['status'] != 'success') {
        setState(() {
          _submitLoading = false;
          _error = response['message'];
        });
        return;
      }

      final imgResponse = await supabaseHelper.uploadProductImage(
          productDraft['productImage'], response['data']['id'].toString());
      print(imgResponse);

      if (imgResponse == null) {
        setState(() {
          _submitLoading = false;
          _error = 'Image upload failed!';
        });
        return;
      }
      print(response['data']['id']);
      print({'img': imgResponse});
      final updateResponse = await supabaseHelper.update('Products', 'id',
          response['data']['id'].toString(), {'img': imgResponse});
      print(updateResponse);

      if (updateResponse['status'] != 'success') {
        setState(() {
          _submitLoading = false;
          _error = response['message'];
        });
        return;
      }

      setState(() => _submitLoading = false);
      _showFinalizeSuccessModal();
    } catch (e) {
      print("Error submitting final submit: $e");
      setState(() => _submitLoading = false);
    }
  }

  void _showFinalizeSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFCFAF3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Successful!",
                style: TextStyle(
                  color: Color(0xFF603B17),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your order was placed successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9C7E60), fontSize: 14),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE27D19),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/products',
                      (r) => false,
                    );
                  },
                  child: const Text(
                    "Go back to Homepage",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Main content stays in memory even while loading
            _currentStep == 1
                ? AddProductStep1(
                    editMode: false,
                    key: const ValueKey(1),
                    draft: productDraft,
                    onNext: (updates) {
                      _updateDraft(updates);
                      _goToStep(2);
                    },
                    onCancel: () => Navigator.pop(context),
                  )
                : AddProductStep2(
                    key: const ValueKey(2),
                    editMode: false,
                    draft: productDraft,
                    categories: _categories,
                    onBack: () => _goToStep(1),
                    onFinalize: (updates) {
                      _updateDraft(updates);
                      debugPrint("FINAL PRODUCT DRAFT: $productDraft");
                      if (productDraft['final']) {
                        debugPrint("FINAL DETECTED!!!!!");
                        setState(() => _submitLoading = true);
                        _finalSubmit();
                      } else {
                        debugPrint("T o T");
                      }
                    },
                  ),

            // 🔶 LOADING OVERLAY
            if (_loading || _submitLoading || _error != null)
              LoadingScreens(
                message: _error != null
                    ? _error!
                    : _loading
                        ? 'Loading product setup...'
                        : 'Submitting your product to the database...',
                error: _error != null,
                onRetry: _error != null
                    ? () {
                        Navigator.pop(context);
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
