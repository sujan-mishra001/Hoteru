import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/core/services/notification_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/delivery_bill_screen.dart';

class DeliveryOrderScreen extends StatefulWidget {
  final int orderId;
  final String customerName;
  final String? deliveryPartnerName;
  final int? deliveryPartnerId;
  final List<Map<String, dynamic>>? navigationItems;

  const DeliveryOrderScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    this.deliveryPartnerName,
    this.deliveryPartnerId,
    this.navigationItems,
  });

  @override
  State<DeliveryOrderScreen> createState() => _DeliveryOrderScreenState();
}

class _DeliveryOrderScreenState extends State<DeliveryOrderScreen> {
  final TableService _tableService = TableService();
  bool _isLoading = true;
  Map<String, dynamic>? _activeOrder;
  List<dynamic> _orderedItems = [];

  @override
  void initState() {
    super.initState();
    _loadActiveOrder();
  }

  Future<void> _loadActiveOrder() async {
    setState(() => _isLoading = true);
    try {
      // Fetch order by ID for delivery orders
      final response = await _tableService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _activeOrder = response;
          _orderedItems = response != null ? (response['items'] as List? ?? []) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tableService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text("Delivery Order", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_orderedItems.isNotEmpty) ...[
                              _buildSectionTitle("Ordered Items"),
                              const SizedBox(height: 12),
                              ..._orderedItems.map((item) => _buildItemTile(item, isBackend: true)),
                              const SizedBox(height: 24),
                            ],
                            if (_orderedItems.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 100),
                                  child: Column(
                                    children: [
                                      Icon(Icons.delivery_dining_rounded, size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text("No items in order", style: GoogleFonts.poppins(color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isOccupied = _activeOrder != null;
    final partnerName = widget.deliveryPartnerName ?? 'Self Delivery';
    
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
              child: const Icon(Icons.delivery_dining_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName.isNotEmpty ? 'Delivery • ${widget.customerName}' : 'Delivery Order',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOccupied 
                        ? "Order #${_activeOrder?['order_number'] ?? widget.orderId} • $partnerName"
                        : "Loading...",
                    style: TextStyle(color: isOccupied ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
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

  Widget _buildBottomActions() {
    final bool hasItems = _orderedItems.isNotEmpty;
    final double total = _orderedItems.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = item['quantity'] as int? ?? 1;
      return sum + (price * qty);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasItems) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text("Rs ${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFFC107))),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasItems ? _goToPayment : null,
                icon: const Icon(Icons.payment),
                label: const Text("Go to Payment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryBillScreen(
          orderId: widget.orderId,
          customerName: widget.customerName,
          deliveryPartnerName: widget.deliveryPartnerName,
          deliveryPartnerId: widget.deliveryPartnerId,
          navigationItems: widget.navigationItems,
        ),
      ),
    ).then((_) => _loadActiveOrder());
  }
}
