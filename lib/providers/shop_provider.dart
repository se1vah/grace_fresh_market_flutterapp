import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/sub_category_item.dart';
import '../services/api_service.dart';

class ShopProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CategoryModel> _categories = [];
  dynamic _selectedCategoryId = 0; // 0 represents "All"
  List<SubCategoryItem> _subCategoryItems = [];
  List<SubCategoryItem> _allSubCategoryItemsCache = [];
  bool _isLoadingCategories = false;
  bool _isLoadingItems = false;
  String _searchQuery = '';
  String? _error;
  Timer? _searchDebounceTimer;

  List<CategoryModel> get categories => _categories;
  dynamic get selectedCategoryId => _selectedCategoryId;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingItems => _isLoadingItems;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Active status filtering requirement:
  // "Only items where status = 'active' should be displayed in the grid container."
  List<SubCategoryItem> get activeItems {
    final activeOnly = _subCategoryItems.where((item) => item.isActive).toList();
    if (_searchQuery.trim().isEmpty) {
      return activeOnly;
    }
    return activeOnly.where((item) {
      return item.subcategoryName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  ShopProvider() {
    initData();
  }

  Future<void> initData() async {
    await fetchCategories();
    await fetchSubCategories();
  }

  // Fetch categories from http://192.168.1.7:3000/api/shop/categories
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _apiService.getCategories();
      // Prepend the mandatory "All" category button
      _categories = [
        CategoryModel(id: 0, categoryName: 'All'),
        ...fetched,
      ];
    } catch (e) {
      _error = 'Failed to load categories';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // Fetch sub-categories based on selected category button's categoryId & search query.
  // Fetches all items for the selected category without page size limits.
  Future<void> fetchSubCategories() async {
    _isLoadingItems = true;
    _error = null;
    notifyListeners();

    try {
      final isAllCategory = _selectedCategoryId == 0 ||
          _selectedCategoryId.toString() == 'all';

      final items = await _apiService.getSubCategories(
        categoryId: isAllCategory ? null : _selectedCategoryId,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery,
      );

      // Cache all items when fetching without category filter and search
      if (isAllCategory && _searchQuery.trim().isEmpty) {
        _allSubCategoryItemsCache = items;
        _subCategoryItems = items;
      } else if (!isAllCategory) {
        // Build map of items returned from API
        final Map<String, SubCategoryItem> mergedMap = {};
        for (final item in items) {
          mergedMap[item.id.toString()] = item;
        }

        // Also merge matching items from full cache in case API capped results
        if (_searchQuery.trim().isEmpty && _allSubCategoryItemsCache.isNotEmpty) {
          final cachedMatches = _allSubCategoryItemsCache.where((item) {
            return item.categoryId != null &&
                item.categoryId.toString() == _selectedCategoryId.toString();
          });
          for (final item in cachedMatches) {
            mergedMap.putIfAbsent(item.id.toString(), () => item);
          }
        }
        _subCategoryItems = mergedMap.values.toList();
      } else {
        _subCategoryItems = items;
      }
    } catch (e) {
      // Fallback to cached items matching category if network query fails
      if (_allSubCategoryItemsCache.isNotEmpty &&
          _selectedCategoryId != 0 &&
          _selectedCategoryId.toString() != 'all') {
        final cachedMatches = _allSubCategoryItemsCache.where((item) {
          return item.categoryId != null &&
              item.categoryId.toString() == _selectedCategoryId.toString();
        }).toList();
        if (cachedMatches.isNotEmpty) {
          _subCategoryItems = cachedMatches;
        } else {
          _error = 'Failed to load items';
        }
      } else {
        _error = 'Failed to load items';
      }
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  void selectCategory(dynamic categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _searchDebounceTimer?.cancel();
    notifyListeners();
    fetchSubCategories();
  }

  void setSearchQuery(String query, {bool immediate = false}) {
    _searchQuery = query;
    notifyListeners();

    _searchDebounceTimer?.cancel();

    if (immediate || query.trim().isEmpty) {
      fetchSubCategories();
    } else {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        fetchSubCategories();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
