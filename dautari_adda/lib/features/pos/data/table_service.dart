import 'dart:async';
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

  Completer<void>? _initCompleter;
  Future<void> get initializationDone => _initCompleter?.future ?? Future.value();

  TableService._internal() {
    _initCompleter = Completer<void>();
    _loadBranchId().then((_) {
      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    });
  }

  Future<void> _loadBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentBranchId = prefs.getInt('selectedBranchId');
    await _loadState();
  }

  int? get currentBranchId => _currentBranchId;

  final Map<int, bool> _tableStatus = {};
  final Map<int, List<CartItem>> _tableCarts = {};
  List<PosTable> _tables = [];
  List<FloorInfo> _floors = [];
  List<BillRecord> _pastBills = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<PosTable> get tables => _tables;
  List<FloorInfo> get floors => _floors;
  List<BillRecord> get pastBills => _pastBills;

  double taxRate = 13.0;
  double serviceChargeRate = 10.0;
  double discountRate = 0.0;

  Future<void> setBranchId(int branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedBranchId', branchId);
    _currentBranchId = branchId;
    await _loadState();
    notifyListeners();
  }

  List<int> get activeTableIds {
    final ids = <int>{};
    // Include tables marked as Occupied/BillRequested in backend
    for (var table in _tables) {
      if (table.status != 'Available') ids.add(table.id);
    }
    return ids.toList();
  }
  
  String getTableName(int id) {
    // If tables list is empty or ID not found, return a default string or try to fetch
    if (_tables.isEmpty) return 'T$id';
    
    try {
      final table = _tables.firstWhere((t) => t.id == id);
      return table.tableId;
    } catch (e) {
       return 'T$id';
    }
  }

  Future<void> fetchFloors({bool force = false}) async {
    try {
      final syncService = SyncService();
      // If sync is running, wait for it
      if (syncService.isSyncing) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return syncService.isSyncing;
        });
      }

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
    try {
      final syncService = SyncService();
      
      // If sync is running, wait for it
      if (syncService.isSyncing) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return syncService.isSyncing;
        });
      }
      
      // 1. Try to use SyncService cache first (Fast path - no loading spinner)
      if (!force && syncService.isCacheValid && syncService.tables.isNotEmpty) {
        if (floorId != null) {
          _tables = syncService.tables.where((t) => t.floorId == floorId).toList();
        } else {
          _tables = syncService.tables;
        }
        // Update local status map
        for (var table in _tables) {
           _tableStatus[table.id] = table.status != 'Available';
        }
        notifyListeners();
        return; // Done using cache
      } 
      
      // 2. Slow path - API Call
      _isLoading = true;
      notifyListeners();

      try {
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

         // Update local status map based on table status
         for (var table in _tables) {
            _tableStatus[table.id] = table.status != 'Available';
         }
      } catch(e) {
         debugPrint("Error fetching tables from API: $e");
      } finally {
         _isLoading = false;
         notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching tables: $e");
      _isLoading = false;
      notifyListeners();
    } 
  }

  // ... (after fetchTables)

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
      debugPrint("TABLE_DEBUG: Updating table $id to status: $status");
      final response = await _apiService.patch('/tables/$id/status', {'status': status});
      if (response.statusCode == 200) {
        debugPrint("TABLE_DEBUG: Table status updated successfully");
        // Refresh tables from backend to get updated status
        await fetchTables();
      } else {
        debugPrint("TABLE_DEBUG: Failed to update table status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error updating table status: $e");
    }
  }

  Future<bool> setHoldTable(int tableId, bool isHold) async {
    try {
      final response = await _apiService.patch('/tables/$tableId', {
        'is_hold_table': isHold ? 'Yes' : 'No',
        'branch_id': _currentBranchId, 
      });
      if (response.statusCode == 200) {
        await fetchTables(force: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error setting hold table: $e");
      return false;
    }
  }

  Future<bool> mergeTables(int primaryTableId, List<int> tableIdsToMerge) async {
    try {
      final response = await _apiService.post('/tables/merge', {
        'primary_table_id': primaryTableId,
        'table_ids': tableIdsToMerge,
        'branch_id': _currentBranchId,
      });
      if (response.statusCode == 200) {
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error merging tables: $e");
      return false;
    }
  }

  Future<bool> unmergeTables(dynamic mergeGroupId) async {
    try {
       final response = await _apiService.post('/tables/unmerge', {
        'merge_group_id': mergeGroupId,
        'branch_id': _currentBranchId,
      });
      if (response.statusCode == 200) {
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error unmerging tables: $e");
      return false;
    }
  }

  Future<void> _loadState() async {
    final syncService = SyncService();
    
    // Execute fetches in parallel
    await Future.wait([
      syncService.syncPOSData(),
      _fetchPastBills(),
      _fetchSettings(),
    ]);
    
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
  }

  Future<void> _fetchPastBills() async {
    try {
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
  }

  Future<void> _fetchSettings() async {
    try {
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
  // Backend Logic:
  // SC = Round(Gross * SC_Rate)
  // VAT = Round((Gross + SC) * Tax_Rate)
  // Total = Gross - Discount + SC + VAT
  
  double calculateDiscountAmount(double subtotal, double discountPercent) {
    return (subtotal * (discountPercent / 100));
  }

  double calculateServiceCharge(double subtotal) {
    // Backend calculates SC on Gross Subtotal
    return (subtotal * (serviceChargeRate / 100));
  }

  double calculateTax(double subtotal, double serviceCharge) {
    // Backend calculates VAT on (Gross Subtotal + SC)
    return ((subtotal + serviceCharge) * (taxRate / 100));
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
    
    // Match backend calculation: round at each step, final total rounded
    final roundedSc = double.parse(sc.toStringAsFixed(2));
    final roundedTax = double.parse(tax.toStringAsFixed(2));
    final roundedDiscount = double.parse(discount.toStringAsFixed(2));
    
    return double.parse((subtotal - roundedDiscount + roundedSc + roundedTax).toStringAsFixed(2));
  }

  Future<bool> confirmOrder(int tableId, List<CartItem> items, {String orderType = 'Table', int? deliveryPartnerId}) async {
    try {
      final subtotal = items.fold(0.0, (sum, i) => sum + (i.menuItem.price * i.quantity));
      
      // Get active order
      Map<String, dynamic>? activeOrder = await getActiveOrderForTable(tableId);

      // Get branch ID if missing
      if (_currentBranchId == null) {
        final prefs = await SharedPreferences.getInstance();
        _currentBranchId = prefs.getInt('selectedBranchId');
      }

      dynamic response;
      
      if (activeOrder != null) {
         // Existing active order -> ADD items to it (creates new KOT for new items only)
         debugPrint("ORDER_CONFIRM_DEBUG: Adding items to existing order ${activeOrder['id']}");
         final requestBody = {
            'items': items.map((i) => {
              'menu_item_id': i.menuItem.id,
              'quantity': i.quantity,
              'price': i.menuItem.price,
              'subtotal': i.menuItem.price * i.quantity,
              'notes': '', 
            }).toList()
         };
         response = await _apiService.post('/orders/${activeOrder['id']}/items', requestBody);

      } else {
        // No active order -> CREATE new order
        debugPrint("ORDER_CONFIRM_DEBUG: Creating new order for table $tableId");
        final discountPercent = getDiscountPercent(tableId);
        final discountAmount = calculateDiscountAmount(subtotal, discountPercent);
        final sc = calculateServiceCharge(subtotal);
        final tax = calculateTax(subtotal, sc);
        
        // Match backend rounding logic
        final roundedSc = double.parse(sc.toStringAsFixed(2));
        final roundedTax = double.parse(tax.toStringAsFixed(2));
        final roundedDiscount = double.parse(discountAmount.toStringAsFixed(2));
        final total = double.parse((subtotal - roundedDiscount + roundedSc + roundedTax).toStringAsFixed(2));

        final requestBody = {
          if (tableId != 0) 'table_id': tableId,
          'order_type': orderType,
          'status': 'Pending',
          'branch_id': _currentBranchId,
          if (deliveryPartnerId != null) 'delivery_partner_id': deliveryPartnerId,
          'gross_amount': subtotal,
          'net_amount': total,
          'discount': roundedDiscount, 
          'items': items.map((i) => {
            'menu_item_id': i.menuItem.id,
            'quantity': i.quantity,
            'price': i.menuItem.price,
            'subtotal': i.menuItem.price * i.quantity,
          }).toList(),
        };
        response = await _apiService.post('/orders', requestBody);
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("ORDER_CONFIRM_DEBUG: Order created successfully");
        debugPrint("ORDER_CONFIRM_DEBUG: Response body: ${response.body}");
        
        _tableCarts[tableId] = [];
        
        // Update table status to Occupied when order placed (dine-in only)
        if (tableId != 0) {
          await _apiService.patch('/tables/$tableId/status', {'status': 'Occupied'});
        }
        
        // KOT is automatically generated by backend when order is created
        // Force refresh to get updated table status
        await SyncService().syncPOSData(force: true);
        if (SyncService().tables.isNotEmpty) {
          _tables = SyncService().tables;
          for (var t in _tables) {
            _tableStatus[t.id] = t.status != 'Available';
          }
        }
        notifyListeners();
        return true;
      } else {
        debugPrint("ORDER_CONFIRM_DEBUG: Order creation failed with status ${response.statusCode}");
        debugPrint("ORDER_CONFIRM_DEBUG: Response body: ${response.body}");
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
          (o) {
            final oTableId = o['table_id'];
            final matchesTable = tableId == 0 ? (oTableId == null) : (oTableId == tableId);
            return matchesTable && 
                 (o['status'] == 'Pending' || o['status'] == 'Draft' || o['status'] == 'In Progress' || o['status'] == 'BillRequested');
          },
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
        _tableCarts[tableId] = []; // Clear cart
        _tableDiscounts.remove(tableId); // Clear discount

        // Free the table when paid (dine-in only, tableId > 0)
        if (tableId > 0) {
          await updateTableStatus(tableId, 'Available');
        }

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

  /// Process payment for merged tables - marks all orders as Paid and frees all tables
  Future<bool> addBillForMerged(
    List<Map<String, dynamic>> orders,
    List<CartItem> combinedItems,
    String paymentMethod,
  ) async {
    if (orders.isEmpty) return false;
    try {
      final subtotal = combinedItems.fold(0.0, (sum, i) => sum + (i.menuItem.price * i.quantity));
      final firstTableId = orders.first['table_id'] as int? ?? 0;
      final discountPercent = getDiscountPercent(firstTableId);
      final discountAmount = calculateDiscountAmount(subtotal, discountPercent);
      final sc = calculateServiceCharge(subtotal);
      final tax = calculateTax(subtotal, sc);
      final total = subtotal - discountAmount + sc + tax;

      for (final order in orders) {
        final orderId = order['id'];
        if (orderId == null) continue;
        final orderNet = (order['net_amount'] ?? order['total_amount'] ?? 0.0) as num;
        final orderNetAmount = orderNet is int ? orderNet.toDouble() : (orderNet as double);
        final res = await _apiService.patch('/orders/$orderId', {
          'status': 'Paid',
          'payment_type': paymentMethod,
          'paid_amount': orderNetAmount,
        });
        if (res.statusCode != 200) return false;
      }

      final tableIds = orders.map((o) => o['table_id'] as int? ?? 0).where((id) => id > 0).toSet();
      for (final tid in tableIds) {
        _tableCarts[tid] = [];
        _tableDiscounts.remove(tid);
        await updateTableStatus(tid, 'Available');
      }

      await _loadState();
      return true;
    } catch (e) {
      debugPrint("Error processing merged bill: $e");
      return false;
    }
  }

  bool isTableBooked(int tableId) {
    // Check if table has active orders from backend
    final table = _tables.firstWhere((t) => t.id == tableId, orElse: () => PosTable(
      id: tableId, 
      tableId: 'T$tableId', 
      floor: '', 
      floorId: 0, 
      status: 'Available'
    ));
    
    final hasActiveOrders = ['Occupied', 'BillRequested', 'Pending'].contains(table.status);
    
    // Also check if there are items in cart for this table
    final hasCartItems = getCart(tableId).isNotEmpty;
    
    debugPrint("TABLE_BOOKED_DEBUG: Table $tableId - Status: ${table.status}, HasActiveOrders: $hasActiveOrders, HasCartItems: $hasCartItems");
    
    return hasActiveOrders || hasCartItems;
  }

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
