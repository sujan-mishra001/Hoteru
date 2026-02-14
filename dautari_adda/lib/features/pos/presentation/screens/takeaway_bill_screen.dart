import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';

class TakeawayBillScreen extends StatefulWidget {
  final int orderId;
  final String customerName;
  final List<Map<String, dynamic>>? navigationItems;

  const TakeawayBillScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    this.navigationItems,
  });

  @override
  State<TakeawayBillScreen> createState() => _TakeawayBillScreenState();
}

class _TakeawayBillScreenState extends State<TakeawayBillScreen> {
  final TableService _tableService = TableService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isPaymentReceived = false;
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  List<dynamic> _qrCodes = [];
  double? _customDiscount;
  bool _isDiscountPercent = true;

  double get subtotal {
    if (_order != null && _order!['gross_amount'] != null) {
      return (_order!['gross_amount'] as num).toDouble();
    }
    return _items.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      return sum + (price * qty);
    });
  }

  double get discountAmount {
    if (_customDiscount != null) {
      return _isDiscountPercent 
          ? subtotal * (_customDiscount! / 100)
          : _customDiscount!;
    }
    if (_order != null && _order!['discount'] != null) {
      return (_order!['discount'] as num).toDouble();
    }
    return 0.0;
  }

  String get discountLabel {
    if (_customDiscount != null) {
      return _isDiscountPercent 
          ? "Discount (${_customDiscount!.toStringAsFixed(0)}%)" 
          : "Discount (Fixed)";
    }
    if (_order != null && _order!['discount'] != null && (_order!['discount'] as num) > 0) {
      return "Discount";
    }
    return "Discount";
  }

  double get serviceCharge {
    if (_order != null && _order!['service_charge_amount'] != null) {
      return (_order!['service_charge_amount'] as num).toDouble();
    }
    return _tableService.calculateServiceCharge(subtotal);
  }

  double get tax {
    if (_order != null && _order!['tax_amount'] != null) {
      return (_order!['tax_amount'] as num).toDouble();
    }
    return _tableService.calculateTax(subtotal, serviceCharge);
  }

  double get grandTotal {
    return subtotal - discountAmount + serviceCharge + tax;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchQRCodes();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _tableService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = response;
          _items = response != null ? (response['items'] as List? ?? []) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        appBar: AppBar(backgroundColor: const Color(0xFFFFC107), title: const Text("Takeaway Bill")),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
      );
    }

    // Calculations
    final subtotal = this.subtotal;
    final discountAmount = this.discountAmount;
    final discountLabel = this.discountLabel;

    final serviceCharge = subtotal * 0.10; // 10% service charge
    final tax = (subtotal + serviceCharge) * 0.13; // 13% tax
    final grandTotal = this.grandTotal;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Takeaway • ${(_order?['customer']?['name'] ?? widget.customerName).isNotEmpty ? (_order?['customer']?['name'] ?? widget.customerName) : 'Bill'}",
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
                ..._items.map((item) => _buildItemRow(item)),
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
                _buildSummaryRow("Service Charge (10%)", "Rs ${serviceCharge.toStringAsFixed(0)}"),
                _buildSummaryRow("Tax (13%)", "Rs ${tax.toStringAsFixed(0)}"),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]));
  }

  Widget _buildItemRow(dynamic item) {
    final String name = item['menu_item']?['name'] ?? 'Unknown';
    final int qty = item['quantity'] ?? 1;
    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text("x$qty", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text("Rs ${(price * qty).toStringAsFixed(0)}"),
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
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.done),
                  label: const Text("Done"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
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
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))],
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
              leading: const Icon(Icons.qr_code),
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
              Image.network("${ApiService.baseHostUrl}${qr['image_url']}", height: 300, fit: BoxFit.contain),
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

      final success = await _tableService.processTakeawayPayment(widget.orderId, method, discount: discountAmount, total: grandTotal);

      setState(() => _isLoading = false);

      if (success) {
        setState(() => _isPaymentReceived = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error recording payment."), backgroundColor: Colors.red));
        }
      }
    }
  }
}
