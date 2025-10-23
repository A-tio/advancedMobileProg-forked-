import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  String _selectedCategory = '';

  int get selectedIndex => _selectedIndex;
  String get selectedCategory => _selectedCategory;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setCategory(String categ) {
    _selectedCategory = categ;
    notifyListeners();
  }
}
