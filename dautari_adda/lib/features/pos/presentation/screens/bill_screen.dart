import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';

class BillScreen extends StatefulWidget {
  final int tableNumber;
  final int? orderId;
  final List<Map<String, dynamic>>? navigationItems;
  final List<Map<String, dynamic>>? accumulatedOrders;
  final String? orderType;
  final String? customerName;
  /// Display name for merged tables e.g. "Merged: T1, T2"
  final String? tableDisplayName;

  const BillScreen({
    super.key,
    required this.tableNumber,
    this.orderId,
    this.navigationItems,
    this.accumulatedOrders,
    this.orderType,
    this.customerName,
    this.tableDisplayName,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final TableService _tableService = TableService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isPaymentReceived = false;
  Map<String, dynamic>? _activeOrder;
  List<CartItem> _displayItems = [];
  List<dynamic> _qrCodes = [];
  double? _customDiscount;
  bool _isDiscountPercent = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchQRCodes();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final acc = widget.accumulatedOrders;
    if (acc != null && acc.isNotEmpty) {
      // Use accumulated orders (merged or single from cashier)
      final allItems = <CartItem>[];
      for (final o in acc) {
        final items = o['items'] as List? ?? [];
        for (final item in items) {
          allItems.add(CartItem(
            menuItem: MenuItem(
              id: item['menu_item_id'],
              name: item['menu_item']?['name'] ?? 'Unknown',
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
            ),
            quantity: item['quantity'] ?? 1,
          ));
        }
      }
      if (mounted) {
        setState(() {
          _activeOrder = acc.first;
          _displayItems = allItems;
          _isLoading = false;
        });
      }
    } else {
      final order = await _tableService.getActiveOrderForTable(widget.tableNumber);
      final localCart = _tableService.getCart(widget.tableNumber);
      if (mounted) {
        setState(() {
          _activeOrder = order;
          if (order != null && order['items'] != null) {
            _displayItems = (order['items'] as List).map((item) {
              return CartItem(
                menuItem: MenuItem(
                  id: item['menu_item_id'],
                  name: item['menu_item']?['name'] ?? 'Unknown',
                  price: (item['price'] as num?)?.toDouble() ?? 0.0,
                ),
                quantity: item['quantity'] ?? 1,
              );
            }).toList();
          } else {
            _displayItems = localCart;
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchQRCodes() async {
    try {
      final response = await _apiService.get('/qr-codes?is_active=true');
      if (response.statusCode == 200) {
        setState(() => _qrCodes = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error fetching QRs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFFFFC107), title: const Text("Bill Overview")),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
      );
    }

    // Calculations
    final subtotal = _displayItems.fold(0.0, (sum, i) => sum + i.totalPrice);
    
    double discountAmount = 0;
    String discountLabel = "Discount";
    
    if (_customDiscount != null) {
      if (_isDiscountPercent) {
        discountAmount = _tableService.calculateDiscountAmount(subtotal, _customDiscount!);
        discountLabel = "Discount (${_customDiscount!.toStringAsFixed(0)}%)";
      } else {
        discountAmount = _customDiscount!;
        discountLabel = "Discount (Fixed)";
      }
    } else {
      final discountPercent = _tableService.getDiscountPercent(widget.tableNumber);
      discountAmount = _tableService.calculateDiscountAmount(subtotal, discountPercent);
      discountLabel = "Discount ($discountPercent%)";
    }

    final serviceCharge = _tableService.calculateServiceCharge(subtotal);
    final taxAmount = _tableService.calculateTax(subtotal, serviceCharge);
    final grandTotal = subtotal - discountAmount + serviceCharge + taxAmount;

    String title = "Bill";
    if (widget.tableDisplayName != null) {
      title = widget.tableDisplayName!;
    } else {
      final orderType = _activeOrder?['order_type'] ?? widget.orderType;
      final customerName = _activeOrder?['customer']?['name'] ?? widget.customerName;
      final deliveryPartner = _activeOrder?['delivery_partner'];
      final partnerName = deliveryPartner?['name'];

      if (orderType != null && orderType.toString().toLowerCase().contains('delivery')) {
        final pName = partnerName ?? 'Delivery';
        title = customerName != null && customerName.toString().isNotEmpty
            ? 'Delivery ($pName) • $customerName'
            : 'Delivery ($pName)';
      } else if (orderType != null && orderType.toString().toLowerCase() == 'takeaway') {
        title = customerName != null && customerName.toString().isNotEmpty
            ? 'Takeaway • $customerName'
            : 'Takeaway';
      } else {
        title = _tableService.getTableName(widget.tableNumber);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Bill • $title",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle("Items"),
                const SizedBox(height: 12),
                ..._displayItems.map((item) => _buildItemRow(item)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow("Subtotal", "Rs ${subtotal.toStringAsFixed(0)}"),
                InkWell(
                  onTap: () => _showDiscountDialog(subtotal),
                  child: _buildSummaryRow(
                    discountLabel, 
                    "- Rs ${discountAmount.toStringAsFixed(0)}", 
                    color: Colors.orange[800],
                    isClickable: true,
                  ),
                ),
                _buildSummaryRow("Service Charge (${_tableService.serviceChargeRate.toStringAsFixed(0)}%)", "Rs ${serviceCharge.toStringAsFixed(0)}"),
                if (_tableService.taxRate > 0)
                  _buildSummaryRow("Tax (${_tableService.taxRate.toStringAsFixed(0)}%)", "Rs ${taxAmount.toStringAsFixed(0)}"),
                const SizedBox(height: 12),
                const Divider(thickness: 1.5),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Rs ${grandTotal.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFFC107))),
                  ],
                ),
              ],
            ),
          ),
          _buildPaymentSection(grandTotal),
        ],
      ),
    );
  }

  Future<void> _handleBillExport() async {
    try {
      // Assuming activeOrder has an ID or using table number
      final orderId = _activeOrder?['id'] ?? widget.orderId;
      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order ID not found for export.")));
        return;
      }
      
      // Call backend to print/export bill
      // Implementation assumes backend handles the actual file generation or printing trigger
      // If we need to download a file, we'd use download logic here similar to reports
      
      // For now, simulating backend trigger
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exporting Bill...")));
      
      // In a real scenario, this might look like:
      // await _apiService.post('/pos/print-bill/$orderId', {});
      
      // After export, user can choose to leave
      // Navigator.popUntil(context, (route) => route.isFirst); 
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e"), backgroundColor: Colors.red));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]));
  }

  Widget _buildItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(item.menuItem.name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text("x${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text("Rs ${item.totalPrice.toStringAsFixed(0)}"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              if (isClickable) ...[
                const SizedBox(width: 4),
                Icon(Icons.edit_rounded, size: 12, color: Colors.grey[400]),
              ]
            ],
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  void _showDiscountDialog(double subtotal) {
    final TextEditingController controller = TextEditingController(
      text: _customDiscount?.toStringAsFixed(0) ?? "",
    );
    bool isPercent = _isDiscountPercent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Apply Discount"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [isPercent, !isPercent],
                onPressed: (index) {
                  setModalState(() => isPercent = index == 0);
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 80, minHeight: 40),
                children: const [
                  Text("%"),
                  Text("Amt"),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPercent ? "Discount Percentage" : "Discount Amount",
                  prefixText: isPercent ? "" : "Rs ",
                  suffixText: isPercent ? "%" : "",
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text) ?? 0.0;
                setState(() {
                  _customDiscount = val;
                  _isDiscountPercent = isPercent;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(double total) {
    if (_isPaymentReceived) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(height: 8),
                    Text("Payment Received", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleBillExport,
                  icon: const Icon(Icons.print),
                  label: const Text("Export / Print Bill"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPaymentMethodBtn("Cash", Icons.money, Colors.green),
                const SizedBox(width: 12),
                _buildPaymentMethodBtn("Card", Icons.credit_card, Colors.blue),
                const SizedBox(width: 12),
                _buildPaymentMethodBtn("QR", Icons.qr_code, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBtn(String method, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _handlePayment(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(method, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePayment(String method) {
    if (method == "QR") {
      _showQRProviderSelection();
    } else {
      _confirmAndProcessPayment(method);
    }
  }

  void _showQRProviderSelection() {
    if (_qrCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No QR providers available.")));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select QR Provider", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ..._qrCodes.map((qr) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    "${ApiService.baseHostUrl}${qr['image_url']}",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 24, color: Colors.grey),
                  ),
                ),
              ),
              title: Text(qr['name']),
              onTap: () {
                Navigator.pop(context);
                _showLargeQR(qr);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showLargeQR(dynamic qr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(qr['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 20),
              Image.network(
                "${ApiService.baseHostUrl}${qr['image_url']}",
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    Text('Failed to load image', style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmAndProcessPayment("QR Pay (${qr['name']})");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("Confirm Payment Received"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndProcessPayment(String method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text("Complete payment of order using $method?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final acc = widget.accumulatedOrders;
      
      double? finalDiscountAmount;
      if (_customDiscount != null) {
        final subtotal = _displayItems.fold(0.0, (sum, i) => sum + i.totalPrice);
        finalDiscountAmount = _isDiscountPercent 
            ? _tableService.calculateDiscountAmount(subtotal, _customDiscount!)
            : _customDiscount!;
      }

      final success = acc != null && acc.length > 1
          ? await _tableService.addBillForMerged(acc, _displayItems, method, discount: finalDiscountAmount)
          : await _tableService.addBill(widget.tableNumber, _displayItems, method, orderType: widget.orderType, discount: finalDiscountAmount);

      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _isPaymentReceived = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error recording payment."), backgroundColor: Colors.red));
        }
      }
    }
  }
}
