
import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';

class OrderWorkflowService with ChangeNotifier {
  Order? _currentOrder;
  PosTable? _selectedTable;

  Order? get currentOrder => _currentOrder;
  PosTable? get selectedTable => _selectedTable;

  void selectTable(PosTable table) {
    _selectedTable = table;
    // TODO: Check for active order on the table
    // If no active order, create a new one
    // If active order exists, resume it
    _currentOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableId: table.id,
      items: [],
      orderType: OrderType.dineIn,
      status: OrderStatus.draft,
    );
    notifyListeners();
  }

  void addItemToOrder(MenuItem item) {
    _currentOrder?.items.add(item);
    notifyListeners();
  }

  void updateOrderType(OrderType orderType) {
    _currentOrder?.orderType = orderType;
    notifyListeners();
  }

  void placeOrder() {
    // TODO: Generate KOT
    // TODO: Send KOT to kitchen
    _currentOrder?.status = OrderStatus.placed;
    notifyListeners();
  }

  void completeOrder() {
    // TODO: Process payment
    _currentOrder?.status = OrderStatus.completed;
    // TODO: Update table status
    _selectedTable = null;
    _currentOrder = null;
    notifyListeners();
  }
}
