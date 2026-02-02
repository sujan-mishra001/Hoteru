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
            name: cat['name'],
            items: catItems.map((i) => MenuItem(
              name: i['name'],
              price: (i['price'] as num).toDouble(),
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

  // Simplified placeholder for other methods
  Future<void> addMainCategory(MenuCategory category) async {
    await _apiService.post('/menu/categories', {'name': category.name, 'type': 'KOT'});
  }

  Future<void> updateCategory(String name, MenuCategory category) async {
    // Placeholder to avoid UI errors
  }

  Future<void> deleteCategory(String name) async {
    // Requires finding ID first in a real scenario
  }
}
