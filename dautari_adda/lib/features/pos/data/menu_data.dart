class MenuItem {
  final int? id;
  final String name;
  final double price;
  final String? description;
  final String? image;
  final bool available;
  final int? categoryId;
  final int? groupId;
  final String kotBot; // KOT or BOT - from backend model
  final bool inventoryTracking; // from backend model

  const MenuItem({
    this.id,
    required this.name,
    this.price = 0.0,
    this.description,
    this.image,
    this.available = true,
    this.categoryId,
    this.groupId,
    this.kotBot = 'KOT',
    this.inventoryTracking = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      if (description != null) 'description': description,
      if (image != null) 'image_url': image,
      'is_available': available,
      if (categoryId != null) 'category_id': categoryId,
      if (groupId != null) 'group_id': groupId,
      'kot_bot': kotBot,
      'inventory_tracking': inventoryTracking,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      description: map['description'],
      image: map['image_url'],
      available: map['is_available'] ?? true,
      categoryId: map['category_id']?.toInt(),
      groupId: map['group_id']?.toInt(),
      kotBot: map['kot_bot'] ?? 'KOT',
      inventoryTracking: map['inventory_tracking'] ?? false,
    );
  }
}

class MenuCategory {
  final int? id;
  final String name;
  final String type; // KOT or BOT - from backend model
  final List<MenuCategory> subCategories;
  final List<MenuItem> items;

  const MenuCategory({
    this.id,
    required this.name,
    this.type = 'KOT',
    this.subCategories = const [],
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'items': items.map((i) => i.toMap()).toList(),
      'subCategories': subCategories.map((s) => s.toMap()).toList(),
    };
  }

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      type: map['type'] ?? 'KOT',
      items: (map['items'] as List? ?? [])
          .map((i) => MenuItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      subCategories: (map['subCategories'] as List? ?? [])
          .map((s) => MenuCategory.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class MenuGroup {
  final int? id;
  final String name;
  final int? categoryId; // From backend model - single category_id
  final String? description;
  final bool isActive; // From backend model

  const MenuGroup({
    this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      'is_active': isActive,
    };
  }

  factory MenuGroup.fromMap(Map<String, dynamic> map) {
    return MenuGroup(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      categoryId: map['category_id']?.toInt(),
      description: map['description'],
      isActive: map['is_active'] ?? true,
    );
  }
}

final List<MenuCategory> menuData = [];
