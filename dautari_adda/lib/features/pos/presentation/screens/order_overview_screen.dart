import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/core/services/notification_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';

class OrderOverviewScreen extends StatefulWidget {
  final int tableId;
  final String tableName;
  final List<Map<String, dynamic>>? navigationItems;
  final String? orderType;
  final String? customerName;
  final int? deliveryPartnerId;

  const OrderOverviewScreen({
    super.key,
    required this.tableId,
    required this.tableName,
    this.navigationItems,
    this.orderType,
    this.customerName,
    this.deliveryPartnerId,
  });

  @override
  State<OrderOverviewScreen> createState() => _OrderOverviewScreenState();
}

class _OrderOverviewScreenState extends State<OrderOverviewScreen> {
  final TableService _tableService = TableService();
  bool _isLoading = false;
  Map<String, dynamic>? _activeOrder;
  List<dynamic> _orderedItems = [];
  String _orderType = 'Table';

  bool get _isOrderTypeInformational => widget.orderType != null;

  @override
  void initState() {
    super.initState();
    if (widget.orderType != null) {
      _orderType = widget.orderType!;
    }
    _loadActiveOrder();
  }

  Future<void> _loadActiveOrder() async {
    setState(() => _isLoading = true);
    final order = await _tableService.getActiveOrderForTable(widget.tableId, orderType: _orderType);
    if (mounted) {
      setState(() {
        _activeOrder = order;
        _orderedItems = order != null ? (order['items'] as List? ?? []) : [];
        if (widget.orderType == null && order != null && order['order_type'] != null) {
          _orderType = order['order_type'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tableService,
      builder: (context, child) {
        final localDraftItems = _tableService.getCart(widget.tableId);
        final bool hasDraft = localDraftItems.isNotEmpty;
        final bool isOccupied = _activeOrder != null;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text("Order Overview", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: const Color(0xFFFFC107),
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadActiveOrder),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
              : Column(
                  children: [
                    _buildHeader(isOccupied),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_orderedItems.isNotEmpty) ...[
                              _buildSectionTitle("Already Ordered (KOT Sent)"),
                              const SizedBox(height: 12),
                              ..._orderedItems.map((item) => _buildItemTile(item, isBackend: true)),
                              const SizedBox(height: 24),
                            ],
                            if (hasDraft) ...[
                              _buildSectionTitle("New Items (Draft)"),
                              const SizedBox(height: 12),
                              ...localDraftItems.map((item) => _buildItemTile(item, isBackend: false)),
                              const SizedBox(height: 24),
                            ],
                            if (_orderedItems.isEmpty && !hasDraft)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 100),
                                  child: Column(
                                    children: [
                                      Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text("No items in order", style: GoogleFonts.poppins(color: Colors.grey[500])),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _goToPlaceOrder,
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
                                        child: const Text("Start Adding Items"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomActions(hasDraft, isOccupied),
                  ],
                ),
        );
      },
    );
  }

  String get _displayName {
    final orderTypeLower = (_activeOrder?['order_type'] ?? widget.orderType ?? 'Table').toString().toLowerCase();
    final backendCustomerName = _activeOrder?['customer']?['name']?.toString();
    final customerName = backendCustomerName ?? widget.customerName;
    
    // Show appropriate label based on order type
    if (orderTypeLower == 'takeaway') {
      return customerName != null && customerName.isNotEmpty ? 'Takeaway • $customerName' : 'Takeaway';
    }
    if (orderTypeLower == 'delivery' || orderTypeLower == 'delivery partner') {
      final deliveryPartner = _activeOrder?['delivery_partner'];
      final partnerName = deliveryPartner?['name']?.toString() ?? 'Self Delivery';
      if (customerName != null && customerName.isNotEmpty) {
        return 'Delivery ($partnerName) • $customerName';
      }
      return 'Delivery ($partnerName)';
    }
    // Table/Dine-in: show table name
    return widget.tableName;
  }
  
  String? get _customerName {
    return _activeOrder?['customer']?['name']?.toString() ?? widget.customerName;
  }

  Widget _buildHeader(bool isOccupied) {
    // Determine order type from active order or widget
    final orderType = (_activeOrder?['order_type'] ?? widget.orderType ?? 'Table').toString();
    final orderTypeLower = orderType.toLowerCase();
    
    // Select appropriate icon and label
    IconData iconData;
    String statusLabel;
    
    if (orderTypeLower == 'takeaway') {
      iconData = Icons.shopping_bag_rounded;
      statusLabel = isOccupied ? "Takeaway Order" : "Takeaway Draft";
    } else if (orderTypeLower == 'delivery' || orderTypeLower == 'delivery partner') {
      iconData = Icons.delivery_dining_rounded;
      statusLabel = isOccupied ? "Delivery Order" : "Delivery Draft";
    } else {
      // Table/Dine-in
      iconData = Icons.table_restaurant_rounded;
      statusLabel = isOccupied ? "HOLD" : "VACANT DRAFT";
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(iconData),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(statusLabel, style: TextStyle(color: isOccupied ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]));
  }

  Widget _buildItemTile(dynamic item, {required bool isBackend}) {
    final String name = isBackend ? item['menu_item']['name'] : (item as CartItem).menuItem.name;
    final int qty = isBackend ? item['quantity'] : (item as CartItem).quantity;
    final double price = isBackend ? (item['price'] as num?)?.toDouble() ?? 0.0 : (item as CartItem).menuItem.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Icon(isBackend ? Icons.check_circle : Icons.pending, color: isBackend ? Colors.green : Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text("x$qty", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text("Rs ${price * qty}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool hasDraft, bool isOccupied) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToPlaceOrder,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Item"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.blueGrey),
                  ),
                ),
                if (hasDraft) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _placeOrder,
                      icon: const Icon(Icons.kitchen),
                      label: const Text("Place Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ]
              ],
            ),
            if (isOccupied || _orderedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToPayment,
                  icon: const Icon(Icons.payment),
                  label: const Text("Go to Payment"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _goToPlaceOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          tableNumber: widget.tableId,
          navigationItems: widget.navigationItems,
          orderType: widget.orderType,
          customerName: widget.customerName,
          deliveryPartnerId: widget.deliveryPartnerId,
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final localCart = _tableService.getCart(widget.tableId);
    if (localCart.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await _tableService.confirmOrder(
      widget.tableId,
      localCart,
      orderType: _orderType,
      deliveryPartnerId: widget.deliveryPartnerId,
      customerName: widget.customerName,
    );
    if (success) {
      if (mounted) {
        await NotificationService().showOrderKOTCreatedNotification(
          'KOT Generated',
          'Order sent to kitchen for $_displayName',
        );
        _loadActiveOrder(); // Refresh to move draft to ordered
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        await NotificationService().showOrderKOTCreatedNotification(
          'Order Failed',
          'Failed to place order for $_displayName',
        );
      }
    }
  }

  void _goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillScreen(
          tableNumber: widget.tableId,
          navigationItems: widget.navigationItems,
          orderType: widget.orderType,
          customerName: _customerName,
        ),
      ),
    );
  }
}
