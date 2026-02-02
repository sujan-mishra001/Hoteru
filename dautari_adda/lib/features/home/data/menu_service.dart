import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';
import 'menu_data.dart';

class MenuService {
  final ApiService _apiService = ApiService();

  // Fetch menu once from the Ratala backend and map to our structure
  Future<List<MenuCategory>> getMenu() async {
    try {
      // 1. Fetch Categories
      final catResponse = await _apiService.get('/menu/categories');
      // 2. Fetch Items
      final itemResponse = await _apiService.get('/menu/items');

      if (catResponse.statusCode == 200 && itemResponse.statusCode == 200) {
        final List categoriesJson = jsonDecode(catResponse.body);
        final List itemsJson = jsonDecode(itemResponse.body);

        // Map items to categories
        List<MenuCategory> menu = categoriesJson.map((cat) {
          final catId = cat['id'];
          final List catItems = itemsJson.where((i) => i['category_id'] == catId).toList();
          
          return MenuCategory(
            id: catId,
            name: cat['name'],
            items: catItems.map((i) => MenuItem(
              id: i['id'],
              name: i['name'],
              price: (i['price'] as num).toDouble(),
              description: i['description'],
              image: i['image_url'],
              available: i['is_available'] ?? true,
            )).toList(),
          );
        }).toList();

        return menu;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Restore Stream for UI components
  Stream<List<MenuCategory>> getMenuStream() {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) => getMenu());
  }

  // ============ CATEGORIES ============
  
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiService.get('/menu/categories');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Add a main category (top-level category)
  Future<bool> addMainCategory(MenuCategory category) async {
    try {
      final response = await _apiService.post('/menu/categories', {
        'name': category.name,
        'type': 'main',
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCategory(String name, String type) async {
    try {
      final response = await _apiService.post('/menu/categories', {
        'name': name,
        'type': type,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Update category by ID
  Future<bool> updateCategory(int categoryId, String name) async {
    try {
      final response = await _apiService.patch('/menu/categories/$categoryId', {
        'name': name,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Update category by name (for UI compatibility)
  Future<bool> updateCategoryByName(String name, MenuCategory updatedCategory) async {
    try {
      // First get all categories to find the ID
      final categories = await getCategories();
      final category = categories.firstWhere((c) => c['name'] == name, orElse: () => null);
      
      if (category == null) return false;
      
      final response = await _apiService.patch('/menu/categories/${category['id']}', {
        'name': updatedCategory.name,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      final response = await _apiService.delete('/menu/categories/$categoryId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete category by name (for UI compatibility)
  Future<bool> deleteCategoryByName(String name) async {
    try {
      // First get all categories to find the ID
      final categories = await getCategories();
      final category = categories.firstWhere((c) => c['name'] == name, orElse: () => null);
      
      if (category == null) return false;
      
      final response = await _apiService.delete('/menu/categories/${category['id']}');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ MENU ITEMS ============
  
  Future<List<dynamic>> getMenuItems() async {
    try {
      final response = await _apiService.get('/menu/items');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addMenuItem(Map<String, dynamic> itemData) async {
    try {
      final response = await _apiService.post('/menu/items', itemData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMenuItem(int itemId, Map<String, dynamic> itemData) async {
    try {
      final response = await _apiService.patch('/menu/items/$itemId', itemData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMenuItem(int itemId) async {
    try {
      final response = await _apiService.delete('/menu/items/$itemId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleItemAvailability(int itemId, bool isAvailable) async {
    try {
      final response = await _apiService.patch('/menu/items/$itemId', {
        'is_available': isAvailable,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ MENU GROUPS ============
  
  Future<List<dynamic>> getMenuGroups() async {
    try {
      final response = await _apiService.get('/menu/groups');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addMenuGroup(Map<String, dynamic> groupData) async {
    try {
      final response = await _apiService.post('/menu/groups', groupData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMenuGroup(int groupId, Map<String, dynamic> groupData) async {
    try {
      final response = await _apiService.patch('/menu/groups/$groupId', groupData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMenuGroup(int groupId) async {
    try {
      final response = await _apiService.delete('/menu/groups/$groupId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ BULK OPERATIONS ============
  
  Future<bool> importMenuItems(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiService.post('/menu/import', {
        'items': items,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> exportMenuItems() async {
    try {
      final response = await _apiService.get('/menu/export');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
