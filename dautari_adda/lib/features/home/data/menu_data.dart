class MenuItem {
  final int? id;
  final String name;
  final double price;
  final String? description;
  final String? image;
  final bool available;
  final int? categoryId;
  final int? groupId;

  const MenuItem({
    this.id,
    required this.name,
    this.price = 0.0,
    this.description,
    this.image,
    this.available = true,
    this.categoryId,
    this.groupId,
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
    );
  }
}

class MenuCategory {
  final int? id;
  final String name;
  final List<MenuCategory> subCategories;
  final List<MenuItem> items;

  const MenuCategory({
    this.id,
    required this.name,
    this.subCategories = const [],
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'items': items.map((i) => i.toMap()).toList(),
      'subCategories': subCategories.map((s) => s.toMap()).toList(),
    };
  }

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id']?.toInt(),
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

class MenuGroup {
  final int? id;
  final String name;
  final String? description;
  final List<int> categoryIds;

  const MenuGroup({
    this.id,
    required this.name,
    this.description,
    this.categoryIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'category_ids': categoryIds,
    };
  }

  factory MenuGroup.fromMap(Map<String, dynamic> map) {
    return MenuGroup(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'],
      categoryIds: List<int>.from(map['category_ids'] ?? []),
    );
  }
}

final List<MenuCategory> menuData = [];
