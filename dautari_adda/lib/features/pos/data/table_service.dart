import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/core/services/sync_service.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';

export 'pos_models.dart'; // Export models for convenience of UI consumers

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
  List<PosTable> _tables = [];
  List<dynamic> _activeOrders = [];
  bool _isLoading = false;

  List<BillRecord> get pastBills => _pastBills;
  List<FloorInfo> get floors => _floors;
  List<PosTable> get tables => _tables;
  List<dynamic> get activeOrders => _activeOrders;
  bool get isLoading => _isLoading;

  double taxRate = 13.0;
  double serviceChargeRate = 10.0;
  double discountRate = 0.0;

  List<int> get activeTableIds {
    final ids = <int>{};
    // Include tables marked as Occupied/BillRequested in backend
    for (var table in _tables) {
      if (table.status != 'Available') ids.add(table.id);
    }
    return ids.toList();
  }

  String getTableName(int id) {
    final table = _tables.firstWhere((t) => t.id == id, orElse: () => PosTable(id: id, tableId: 'T$id', floor: '', floorId: 0, status: ''));
    return table.tableId;
  }

  Future<void> fetchFloors({bool force = false}) async {
    try {
      final syncService = SyncService();
      if (!force && syncService.isCacheValid && syncService.floors.isNotEmpty) {
        _floors = syncService.floors;
        notifyListeners();
        return;
      }
      
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

  Future<void> fetchTables({int? floorId, bool force = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final syncService = SyncService();
      
      // 1. Try to use SyncService cache first
      if (!force && syncService.isCacheValid && syncService.tables.isNotEmpty) {
        if (floorId != null) {
          _tables = syncService.tables.where((t) => t.floorId == floorId).toList();
        } else {
          _tables = syncService.tables;
        }
      } else {
         // Fallback to API if cache invalid or forced
         String url = '/tables';
         final params = <String>[];
         if (_currentBranchId != null) params.add('branch_id=$_currentBranchId');
         if (floorId != null) params.add('floor_id=$floorId');
         if (params.isNotEmpty) url += '?${params.join("&")}';
         
         final response = await _apiService.get(url);
         if (response.statusCode == 200) {
           final List data = jsonDecode(response.body);
           _tables = data.map((json) => PosTable.fromJson(json)).toList();
         }
      }

      // Update local status map based on table status
      for (var table in _tables) {
         _tableStatus[table.id] = table.status != 'Available';
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching tables: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFloor(String name) async {
    try {
      final response = await _apiService.post('/floors', {
        'name': name,
        'branch_id': _currentBranchId,
      });
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
        'branch_id': _currentBranchId, // Explicitly send branch_id
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

  Future<bool> updateTable(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/tables/$id', data);
      if (response.statusCode == 200) {
        await fetchTables(floorId: data['floor_id']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating table: $e");
      return false;
    }
  }

  Future<bool> deleteTable(int id) async {
    try {
      final response = await _apiService.delete('/tables/$id');
      if (response.statusCode == 200) {
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting table: $e");
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
    final syncService = SyncService();
    await syncService.syncPOSData();
    
    if (syncService.floors.isNotEmpty) {
      _floors = syncService.floors;
    } else {
      await fetchFloors();
    }
    
    if (syncService.tables.isNotEmpty) {
      _tables = syncService.tables;
      for (var table in _tables) {
        _tableStatus[table.id] = table.status != 'Available';
      }
    } else {
      if (_floors.isNotEmpty) {
        await fetchTables(floorId: _floors.first.id);
      } else {
        await fetchTables();
      }
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
          amount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: json['payment_type'] ?? 'Cash',
          date: DateTime.parse(json['created_at']),
          items: [], 
        )).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading past bills: $e");
    }

    try {
      // Fetch settings
      final settings = await _apiService.get('/settings/company');
      if (settings.statusCode == 200) {
        final data = jsonDecode(settings.body);
        taxRate = (data['tax_rate'] ?? 13.0).toDouble();
        serviceChargeRate = (data['service_charge_rate'] ?? 10.0).toDouble();
        discountRate = (data['discount_rate'] ?? 0.0).toDouble();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  // Discount Storage per table (percentage)
  final Map<int, double> _tableDiscounts = {};

  void setDiscount(int tableId, double discountPercent) {
    if (discountPercent < 0 || discountPercent > 100) return;
    _tableDiscounts[tableId] = discountPercent;
    notifyListeners();
  }

  double getDiscountPercent(int tableId) => _tableDiscounts[tableId] ?? discountRate;

  double getTableTotal(int tableId) {
    final cart = getCart(tableId);
    return cart.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Pure calculation helpers
  // Web App Logic:
  // SC = Round(Subtotal * SC_Rate)
  // VAT = Round((Subtotal + SC) * Tax_Rate)
  // Total = Subtotal - Discount + SC + VAT
  
  double calculateDiscountAmount(double subtotal, double discountPercent) {
    return (subtotal * (discountPercent / 100)).roundToDouble();
  }

  double calculateServiceCharge(double subtotal) {
    // Web App calculates SC on Gross Subtotal
    return (subtotal * (serviceChargeRate / 100)).roundToDouble();
  }

  double calculateTax(double subtotal, double serviceCharge) {
    // Web App calculates VAT on (Gross Subtotal + SC)
    return ((subtotal + serviceCharge) * (taxRate / 100)).roundToDouble();
  }

  // Stateful getters (legacy support, mostly for local cart only)
  double getDiscountAmount(int tableId) {
    final subtotal = getTableTotal(tableId);
    final discountPercent = getDiscountPercent(tableId);
    return calculateDiscountAmount(subtotal, discountPercent);
  }
  
  double getTaxableAmount(int tableId) {
    // Note: In Web App logic, 'Taxable Amount' for SC/VAT purpose is actually just Subtotal.
    // But if we need 'Amount after discount' for display:
    return getTableTotal(tableId) - getDiscountAmount(tableId);
  }

  double getServiceCharge(int tableId) {
    final subtotal = getTableTotal(tableId);  
    return calculateServiceCharge(subtotal);
  }

  double getTaxAmount(int tableId) {
    final subtotal = getTableTotal(tableId);
    final sc = getServiceCharge(tableId);
    return calculateTax(subtotal, sc);
  }

  double getNetTotal(int tableId) {
    final subtotal = getTableTotal(tableId);
    final discount = getDiscountAmount(tableId);
    final sc = getServiceCharge(tableId);
    final tax = getTaxAmount(tableId);
    return (subtotal - discount + sc + tax).roundToDouble();
  }

  Future<bool> confirmOrder(int tableId, List<CartItem> items, {String orderType = 'Table'}) async {
    try {
      final subtotal = items.fold(0.0, (sum, i) => sum + (i.menuItem.price * i.quantity));
      
      final discountPercent = getDiscountPercent(tableId);
      final discountAmount = calculateDiscountAmount(subtotal, discountPercent);
      final sc = calculateServiceCharge(subtotal);
      final tax = calculateTax(subtotal, sc);
      final total = subtotal - discountAmount + sc + tax;
      
      // Get branch ID if missing
      if (_currentBranchId == null) {
        final prefs = await SharedPreferences.getInstance();
        _currentBranchId = prefs.getInt('selected_branch_id');
      }

      final requestBody = {
        'table_id': tableId,
        'order_type': orderType,
        'status': 'Pending',
        'branch_id': _currentBranchId,
        'gross_amount': subtotal,
        'net_amount': total,
        'tax': tax,
        'service_charge': sc,
        'discount': discountAmount, 
        'items': items.map((i) => {
          'menu_item_id': i.menuItem.id,
          'quantity': i.quantity,
          'price': i.menuItem.price,
          'subtotal': i.menuItem.price * i.quantity,
        }).toList(),
      };
      final response = await _apiService.post('/orders', requestBody);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _tableCarts[tableId] = [];
        // Explicitly refresh tables to sync from backend
        await _loadState();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error confirming order: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getActiveOrderForTable(int tableId) async {
    try {
      // Fetch all orders and find active one for this table
      String ordersUrl = '/orders?status=Pending,Draft,In Progress,BillRequested';
      if (_currentBranchId != null) ordersUrl += '&branch_id=$_currentBranchId';
      final response = await _apiService.get(ordersUrl);
      
      if (response.statusCode == 200) {
        final List orders = jsonDecode(response.body);
        final activeOrder = orders.firstWhere(
          (o) => o['table_id'] == tableId && 
                 (o['status'] == 'Pending' || o['status'] == 'Draft' || o['status'] == 'In Progress' || o['status'] == 'BillRequested'),
          orElse: () => null,
        );
        
        if (activeOrder != null) {
          // Fetch full order details with items
          final detailsResponse = await _apiService.get('/orders/${activeOrder['id']}');
          if (detailsResponse.statusCode == 200) {
            return jsonDecode(detailsResponse.body);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching active order: $e");
      return null;
    }
  }

  Future<bool> addBill(int tableId, List<CartItem> items, String paymentMethod) async {
    try {
      // Re-calculate consistently
      final subtotal = items.fold(0.0, (sum, i) => sum + (i.menuItem.price * i.quantity));
      final discountPercent = getDiscountPercent(tableId);
      final discountAmount = calculateDiscountAmount(subtotal, discountPercent);
      final sc = calculateServiceCharge(subtotal);
      final tax = calculateTax(subtotal, sc);
      final total = subtotal - discountAmount + sc + tax;

      // Fetch fresh active order for this table
      Map<String, dynamic>? backendOrder = await getActiveOrderForTable(tableId);
      
      dynamic response;
      if (backendOrder != null) {
        // Update existing order to Paid
        response = await _apiService.patch('/orders/${backendOrder['id']}', {
          'status': 'Paid',
          'payment_type': paymentMethod,
          // Update financials just in case they changed
          'gross_amount': subtotal,
          'discount': discountAmount,
          'service_charge': sc,
          'tax': tax,
          'net_amount': total,
          'paid_amount': total,
        });
      } else {
        // Create new Paid order (walk-in or quick pay)
        response = await _apiService.post('/orders', {
          'table_id': tableId,
          'order_type': 'Table',
          'status': 'Paid',
          'payment_type': paymentMethod,
          'branch_id': _currentBranchId,
          'gross_amount': subtotal,
          'net_amount': total,
          'paid_amount': total,
          'discount': discountAmount,
          'service_charge': sc,
          'tax': tax,
          'items': items.map((i) => {
            'menu_item_id': i.menuItem.id,
            'quantity': i.quantity,
            'price': i.menuItem.price,
            'subtotal': i.menuItem.price * i.quantity,
          }).toList(),
        });
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _tableCarts[tableId] = [];
        _tableDiscounts.remove(tableId); // Clear discount
        
        // Explicitly free the table
        await updateTableStatus(tableId, 'Available');
        
        // Refresh state
        await _loadState();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error processing bill: $e");
      return false;
    }
  }

  bool isTableBooked(int tableId) => _tables.any((t) => t.id == tableId && t.status != 'Available');

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


  Future<bool> printKOT(int kotId) async {
    try {
      final response = await _apiService.post('/kots/$kotId/print', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<PosTable>> getTables() async {
    await fetchTables();
    return _tables;
  }
}
