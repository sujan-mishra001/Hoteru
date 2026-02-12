import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';

class OrderOverviewScreen extends StatefulWidget {
  final int tableId;
  final String tableName;
  final List<Map<String, dynamic>>? navigationItems;

  const OrderOverviewScreen({
    super.key,
    required this.tableId,
    required this.tableName,
    this.navigationItems,
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

  @override
  void initState() {
    super.initState();
    _loadActiveOrder();
  }

  Future<void> _loadActiveOrder() async {
    setState(() => _isLoading = true);
    final order = await _tableService.getActiveOrderForTable(widget.tableId);
    if (mounted) {
      setState(() {
        _activeOrder = order;
        _orderedItems = order != null ? (order['items'] as List? ?? []) : [];
        if (order != null && order['order_type'] != null) {
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
                            if (hasDraft) ...[
                              _buildSectionTitle("Order Type"),
                              const SizedBox(height: 12),
                              _buildOrderTypeSelector(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildBottomActions(hasDraft, isOccupied),
                  ],
                ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: 0, 
            onTap: (index) {
               Navigator.pop(context, index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.grey[400],
            unselectedItemColor: Colors.grey[400],
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
               BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
               BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
               BottomNavigationBarItem(icon: Icon(Icons.kitchen_rounded), label: 'KOT/BOT'),
               BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Cashier'),
               BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildHeader(bool isOccupied) {
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
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.table_restaurant_rounded)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.tableName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(isOccupied ? "Occupied" : "Draft Order", style: TextStyle(color: isOccupied ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildOrderTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTypeBtn("Dine-in", Icons.restaurant),
        _buildTypeBtn("Takeaway", Icons.shopping_bag),
        _buildTypeBtn("Delivery", Icons.delivery_dining),
      ],
    );
  }

  Widget _buildTypeBtn(String type, IconData icon) {
    final isSelected = _orderType == (type == "Dine-in" ? "Table" : type);
    final actualType = type == "Dine-in" ? "Table" : type;
    return GestureDetector(
      onTap: () => setState(() => _orderType = actualType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC107).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFFC107) : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.black87 : Colors.grey, size: 20),
            Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.black87 : Colors.grey)),
          ],
        ),
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
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final localCart = _tableService.getCart(widget.tableId);
    if (localCart.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await _tableService.confirmOrder(widget.tableId, localCart, orderType: _orderType);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("KOT Generated & Sent to Kitchen!"), backgroundColor: Colors.green));
        _loadActiveOrder(); // Refresh to move draft to ordered
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to place order."), backgroundColor: Colors.red));
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
        ),
      ),
    );
  }
}
