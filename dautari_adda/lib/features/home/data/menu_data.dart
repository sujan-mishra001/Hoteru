class MenuItem {
  final String name;
  final double price;

  const MenuItem({required this.name, this.price = 0.0});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
    );
  }
}

class MenuCategory {
  final String name;
  final List<MenuCategory> subCategories;
  final List<MenuItem> items;

  const MenuCategory({
    required this.name,
    this.subCategories = const [],
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items.map((i) => i.toMap()).toList(),
      'subCategories': subCategories.map((s) => s.toMap()).toList(),
    };
  }

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      name: map['name'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((i) => MenuItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      subCategories: (map['subCategories'] as List? ?? [])
          .map((s) => MenuCategory.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

final List<MenuCategory> menuData = [];
