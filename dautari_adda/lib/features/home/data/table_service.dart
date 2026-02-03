import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/core/services/api_service.dart';
import 'menu_data.dart';

class BillRecord {
  final int? id;
  final String? orderNumber;
  final String? userId;
  final int? tableId;
  final int? tableNumber; // For backward compatibility
  final double amount;
  final double grossAmount;
  final double discount;
  final double netAmount;
  final String paymentMethod;
  final String status;
  final String orderType; // Table, Takeaway, Self Delivery, Delivery Partner, Pay First
  final DateTime date;
  final List<CartItem> items;

  BillRecord({
    this.id,
    this.orderNumber,
    this.userId,
    this.tableId,
    this.tableNumber,
    required this.amount,
    this.grossAmount = 0,
    this.discount = 0,
    this.netAmount = 0,
    required this.paymentMethod,
    this.status = 'Paid',
    this.orderType = 'Table',
    required this.date,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (orderNumber != null) 'order_number': orderNumber,
      'user_id': userId,
      'table_id': tableId,
      'table_number': tableNumber ?? tableId,
      'amount': amount,
      'gross_amount': grossAmount,
      'discount': discount,
      'net_amount': netAmount,
      'payment_method': paymentMethod,
      'status': status,
      'order_type': orderType,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  factory BillRecord.fromMap(Map<String, dynamic> map) {
    return BillRecord(
      id: map['id']?.toInt(),
      orderNumber: map['order_number'],
      userId: map['created_by']?.toString(),
      tableId: map['table_id']?.toInt(),
      tableNumber: map['table_id']?.toInt() ?? map['table_number']?.toInt(),
      amount: (map['total_amount'] ?? map['amount'] ?? 0).toDouble(),
      grossAmount: (map['gross_amount'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      netAmount: (map['net_amount'] ?? 0).toDouble(),
      paymentMethod: map['payment_type'] ?? map['payment_method'] ?? 'Cash',
      status: map['status'] ?? 'Paid',
      orderType: map['order_type'] ?? 'Table',
      date: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      items: [],
    );
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menu_item_id': menuItem.id ?? 1,
      'quantity': quantity,
      'price': menuItem.price,
    };
  }
}

class FloorInfo {
  final int id;
  final String name;
  final int displayOrder;
  final bool isActive; // From backend model

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

class TableInfo {
  final int id;
  final String tableId;
  final String floor;
  final int floorId;
  final String status;
  final int capacity;
  final int kotCount;
  final double totalAmount;
  final String tableType; // From backend model: Regular, VIP, Outdoor
  final bool isActive; // From backend model
  final int displayOrder; // From backend model
  final String isHoldTable; // From backend model: Yes, No
  final String? holdTableName; // From backend model
  final int? branchId; // From backend model for branch isolation

  TableInfo({
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
      tableType: json['table_type'] ?? 'Regular',
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      isHoldTable: json['is_hold_table'] ?? 'No',
      holdTableName: json['hold_table_name'],
      branchId: json['branch_id']?.toInt(),
    );
  }
}

class TableService extends ChangeNotifier {
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;

  final ApiService _apiService = ApiService();

  int? _currentBranchId;

  TableService._internal() {
    _loadBranchId();
  }

  Future<void> _loadBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentBranchId = prefs.getInt('selectedBranchId');
    if (_currentBranchId != null) {
      _loadState();
    }
  }

  Future<void> setBranchId(int branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedBranchId', branchId);
    _currentBranchId = branchId;
    await _loadState();
    notifyListeners();
  }

  int? get currentBranchId => _currentBranchId;

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
      String endpoint = '/floors';
      if (_currentBranchId != null) {
        endpoint += '?branch_id=$_currentBranchId';
      }
      final response = await _apiService.get(endpoint);
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
      String url = '/tables';
      final params = <String>[];
      if (_currentBranchId != null) params.add('branch_id=$_currentBranchId');
      if (floorId != null) params.add('floor_id=$floorId');
      if (params.isNotEmpty) url += '?${params.join("&")}';
      final response = await _apiService.get(url);
      
      // Also fetch active orders to sync table booking
      String ordersUrl = '/orders?status=Pending';
      if (_currentBranchId != null) ordersUrl += '&branch_id=$_currentBranchId';
      final ordersResponse = await _apiService.get(ordersUrl);
      
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
      String billsUrl = '/orders?status=Paid';
      if (_currentBranchId != null) billsUrl += '&branch_id=$_currentBranchId';
      final billsResponse = await _apiService.get(billsUrl);
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
      final requestBody = {
        'table_id': tableId,
        'order_type': 'Table',
        'status': 'Pending',
        'branch_id': _currentBranchId,
        'items': items.map((i) => {
          'menu_item_id': i.menuItem.id,
          'quantity': i.quantity,
          'price': i.menuItem.price,
        }).toList(),
      };
      final response = await _apiService.post('/orders', requestBody);
      
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
          'branch_id': _currentBranchId,
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
