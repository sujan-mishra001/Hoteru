class FloorInfo {
  final int id;
  final String name;
  final int displayOrder;
  final bool isActive;

  FloorInfo({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.isActive = true,
  });

  factory FloorInfo.fromJson(Map<String, dynamic> json) {
    return FloorInfo(
      id: json['id'],
      name: json['name'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}


enum OrderStatus {
  draft,
  placed,
  completed,
  cancelled,
}

enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

class Order {
  final String id;
  final int tableId;
  final List<MenuItem> items;
  OrderStatus status;
  OrderType orderType;

  Order({
    required this.id,
    required this.tableId,
    this.items = const [],
    this.status = OrderStatus.draft,
    this.orderType = OrderType.dineIn,
  });
}

@deprecated
class PosTableInfo {
  final int id;
  final String tableId;
  final String floor;
  final int floorId;
  final String status;
  final int capacity;
  final int kotCount;
  final double totalAmount;
  final String tableType;
  final bool isActive;
  final int displayOrder;
  final String isHoldTable;
  final String? holdTableName;
  final int? branchId;

  PosTableInfo({
    required this.id,
    required this.tableId,
    required this.floor,
    required this.floorId,
    required this.status,
    this.capacity = 4,
    this.kotCount = 0,
    this.totalAmount = 0,
    this.tableType = 'Regular',
    this.isActive = true,
    this.displayOrder = 0,
    this.isHoldTable = 'No',
    this.holdTableName,
    this.branchId,
  });

  factory PosTableInfo.fromJson(Map<String, dynamic> json) {
    return PosTableInfo(
      id: json['id'],
      tableId: json['table_id'],
      floor: json['floor'] ?? '',
      floorId: json['floor_id'] ?? 0,
      status: json['status'] ?? 'Available',
      capacity: json['capacity'] ?? 4,
      kotCount: json['kot_count'] ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      tableType: json['table_type'] ?? 'Regular',
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      isHoldTable: json['is_hold_table'] ?? 'No',
      holdTableName: json['hold_table_name'],
      branchId: json['branch_id']?.toInt(),
    );
  }
}

class PosTable {
  final int id;
  final String tableId;
  final String floor;
  final int floorId;
  final String status;
  final int capacity;
  final int kotCount;
  final double totalAmount;
  final String tableType;
  final bool isActive;
  final int displayOrder;
  final String isHoldTable;
  final String? holdTableName;
  /// merge_group_id from backend - can be int (bulk merge) or String (pairwise merge)
  final dynamic mergeGroupId;
  final int? branchId;

  PosTable({
    required this.id,
    required this.tableId,
    required this.floor,
    required this.floorId,
    required this.status,
    this.capacity = 4,
    this.kotCount = 0,
    this.totalAmount = 0,
    this.tableType = 'Regular',
    this.isActive = true,
    this.displayOrder = 0,
    this.isHoldTable = 'No',
    this.holdTableName,
    this.mergeGroupId,
    this.branchId,
  });

  factory PosTable.fromJson(Map<String, dynamic> json) {
    return PosTable(
      id: json['id'],
      tableId: json['table_id'],
      floor: json['floor'] ?? '',
      floorId: json['floor_id'] ?? 0,
      status: json['status'] ?? 'Available',
      capacity: json['capacity'] ?? 4,
      kotCount: json['kot_count'] ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      tableType: json['table_type'] ?? 'Regular',
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      isHoldTable: json['is_hold_table'] ?? 'No',
      holdTableName: json['hold_table_name'],
      mergeGroupId: json['merge_group_id'],
      branchId: json['branch_id']?.toInt(),
    );
  }
}
class MenuItem {
  final int? id;
  final String name;
  final double price;
  final String? description;
  final String? image;
  final bool available;
  final int? categoryId;
  final int? groupId;
  final String kotBot;
  final bool inventoryTracking;

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
      if (image != null) 'image': image,
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
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      image: map['image'] ?? map['image_url'], // Support both for safety
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
  final String type;
  final String? image;
  final List<MenuCategory> subCategories;
  final List<MenuItem> items;

  const MenuCategory({
    this.id,
    required this.name,
    this.type = 'KOT',
    this.image,
    this.subCategories = const [],
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      if (image != null) 'image': image,
      'items': items.map((i) => i.toMap()).toList(),
      'subCategories': subCategories.map((s) => s.toMap()).toList(),
    };
  }

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      type: map['type'] ?? 'KOT',
      image: map['image'],
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
  final int? categoryId;
  final String? description;
  final bool isActive;

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
