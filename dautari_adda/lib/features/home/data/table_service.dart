import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dautari_adda/core/services/api_service.dart';
import 'menu_data.dart';

class BillRecord {
  final String? userId;
  final int tableNumber;
  final double amount;
  final String paymentMethod;
  final DateTime date;
  final List<CartItem> items;

  BillRecord({
    this.userId,
    required this.tableNumber,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'table_number': tableNumber,
      'amount': amount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': 1, // Placeholder: in real app, MenuItem should have ID
      'quantity': quantity,
      'price': menuItem.price,
    };
  }
}

class FloorInfo {
  final int id;
  final String name;
  final int displayOrder;

  FloorInfo({required this.id, required this.name, required this.displayOrder});

  factory FloorInfo.fromJson(Map<String, dynamic> json) {
    return FloorInfo(
      id: json['id'],
      name: json['name'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

class TableInfo {
  final int id;
  final String tableId;
  final String floor;
  final int floorId;
  final String status;
  final int capacity;
  final int kotCount;
  final double totalAmount;

  TableInfo({
    required this.id,
    required this.tableId,
    required this.floor,
    required this.floorId,
    required this.status,
    this.capacity = 4,
    this.kotCount = 0,
    this.totalAmount = 0,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      id: json['id'],
      tableId: json['table_id'],
      floor: json['floor'] ?? '',
      floorId: json['floor_id'] ?? 0,
      status: json['status'] ?? 'Available',
      capacity: json['capacity'] ?? 4,
      kotCount: json['kot_count'] ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TableService extends ChangeNotifier {
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;

  final ApiService _apiService = ApiService();

  TableService._internal() {
    _loadState();
  }

  final Map<int, bool> _tableStatus = {};
  final Map<int, List<CartItem>> _tableCarts = {};
  final Map<int, String> _tableNames = {};
  List<BillRecord> _pastBills = [];
  List<FloorInfo> _floors = [];
  List<TableInfo> _tables = [];
  List<dynamic> _activeOrders = [];
  bool _isLoading = false;

  List<BillRecord> get pastBills => _pastBills;
  List<FloorInfo> get floors => _floors;
  List<TableInfo> get tables => _tables;
  List<dynamic> get activeOrders => _activeOrders;
  bool get isLoading => _isLoading;

  List<int> get activeTableIds {
    final ids = <int>{};
    // Include tables from active orders in backend
    for (var order in _activeOrders) {
      if (order['table_id'] != null) ids.add(order['table_id']);
    }
    // Include tables with local items
    for (var entry in _tableCarts.entries) {
      if (entry.value.isNotEmpty) ids.add(entry.key);
    }
    // Include tables marked as Occupied/BillRequested in backend
    for (var table in _tables) {
      if (table.status != 'Available') ids.add(table.id);
    }
    return ids.toList();
  }

  String getTableName(int id) {
    final table = _tables.firstWhere((t) => t.id == id, orElse: () => TableInfo(id: id, tableId: 'T$id', floor: '', floorId: 0, status: ''));
    return table.tableId;
  }

  Future<void> fetchFloors() async {
    try {
      final response = await _apiService.get('/floors');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _floors = data.map((json) => FloorInfo.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching floors: $e");
    }
  }

  Future<void> fetchTables({int? floorId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final String url = floorId != null ? '/tables?floor_id=$floorId' : '/tables';
      final response = await _apiService.get(url);
      
      // Also fetch active orders to sync table booking
      final ordersResponse = await _apiService.get('/orders?status=Pending');
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _tables = data.map((json) => TableInfo.fromJson(json)).toList();
        for (var table in _tables) {
          _tableStatus[table.id] = table.status != 'Available';
        }
      }
      
      if (ordersResponse.statusCode == 200) {
        _activeOrders = jsonDecode(ordersResponse.body);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching tables/orders: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFloor(String name) async {
    try {
      final response = await _apiService.post('/floors', {'name': name});
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFloors();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error creating floor: $e");
      return false;
    }
  }

  Future<bool> createTable(String tableId, int floorId, {int capacity = 4, String type = "Regular"}) async {
    try {
      final response = await _apiService.post('/tables', {
        'table_id': tableId,
        'floor_id': floorId,
        'status': 'Available',
        'capacity': capacity,
        'table_type': type,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTables(floorId: floorId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error creating table: $e");
      return false;
    }
  }

  Future<void> updateTableStatus(int id, String status) async {
    try {
      final response = await _apiService.patch('/tables/$id/status', {'status': status});
      if (response.statusCode == 200) {
        await fetchTables(floorId: _tables.firstWhere((t) => t.id == id).floorId);
      }
    } catch (e) {
      debugPrint("Error updating table status: $e");
    }
  }

  Future<void> _loadState() async {
    await fetchFloors();
    if (_floors.isNotEmpty) {
      await fetchTables(floorId: _floors.first.id);
    } else {
      await fetchTables();
    }
    
    try {
      // Fetch past bills
      final billsResponse = await _apiService.get('/orders?status=Paid');
      if (billsResponse.statusCode == 200) {
        final List billsJson = jsonDecode(billsResponse.body);
        _pastBills = billsJson.map((json) => BillRecord(
          tableNumber: json['table_id'] ?? 0,
          amount: (json['total_amount'] as num).toDouble(),
          paymentMethod: json['payment_type'] ?? 'Cash',
          date: DateTime.parse(json['created_at']),
          items: [], 
        )).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading past bills: $e");
    }
  }

  Future<bool> confirmOrder(int tableId, List<CartItem> items) async {
    try {
      final response = await _apiService.post('/orders', {
        'table_id': tableId,
        'order_type': 'Table',
        'status': 'Pending',
        'items': items.map((i) => {
          'menu_item_id': i.menuItem.id,
          'quantity': i.quantity,
          'price': i.menuItem.price,
        }).toList(),
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _tableCarts[tableId] = [];
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error confirming order: $e");
      return false;
    }
  }

  Future<bool> addBill(int tableId, List<CartItem> items, String paymentMethod) async {
    try {
      // Find active order for this table if any
      final backendOrder = _activeOrders.firstWhere((o) => o['table_id'] == tableId, orElse: () => null);
      
      dynamic response;
      if (backendOrder != null) {
        // Update existing order to Paid
        response = await _apiService.patch('/orders/${backendOrder['id']}', {
          'status': 'Paid',
          'payment_type': paymentMethod,
        });
      } else {
        // Create new Paid order (walk-in or quick pay)
        response = await _apiService.post('/orders', {
          'table_id': tableId,
          'order_type': 'Table',
          'status': 'Paid',
          'payment_type': paymentMethod,
          'items': items.map((i) => {
            'menu_item_id': i.menuItem.id,
            'quantity': i.quantity,
            'price': i.menuItem.price,
          }).toList(),
        });
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _tableCarts[tableId] = [];
        await _loadState();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error processing bill: $e");
      return false;
    }
  }

  bool isTableBooked(int tableId) => _tables.any((t) => t.id == tableId && t.status != 'Available') || (_tableCarts[tableId]?.isNotEmpty ?? false);

  void clearTable(int tableId) {
    _tableCarts[tableId] = [];
    notifyListeners();
  }

  List<CartItem> getCart(int tableId) => _tableCarts[tableId] ?? [];

  void addToCart(int tableId, MenuItem item, int quantity) {
    if (!_tableCarts.containsKey(tableId)) _tableCarts[tableId] = [];
    final cart = _tableCarts[tableId]!;
    final index = cart.indexWhere((element) => element.menuItem.name == item.name);

    if (index != -1) {
      cart[index].quantity += quantity;
    } else {
      cart.add(CartItem(menuItem: item, quantity: quantity));
    }
    notifyListeners();
  }

  double getTableTotal(int tableId) {
    final cart = getCart(tableId);
    return cart.fold(0, (sum, item) => sum + item.totalPrice);
  }
}
