import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';

class DeliveryBillScreen extends StatefulWidget {
  final int orderId;
  final String customerName;
  final String? deliveryPartnerName;
  final int? deliveryPartnerId;
  final List<Map<String, dynamic>>? navigationItems;

  const DeliveryBillScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    this.deliveryPartnerName,
    this.deliveryPartnerId,
    this.navigationItems,
  });

  @override
  State<DeliveryBillScreen> createState() => _DeliveryBillScreenState();
}

class _DeliveryBillScreenState extends State<DeliveryBillScreen> {
  final TableService _tableService = TableService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isPaymentReceived = false;
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  List<dynamic> _qrCodes = [];

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
        appBar: AppBar(backgroundColor: const Color(0xFFFFC107), title: const Text("Delivery Bill")),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
      );
    }

    // Calculations
    final subtotal = _items.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = item['quantity'] as int? ?? 1;
      return sum + (price * qty);
    });
    final serviceCharge = subtotal * 0.10; // 10% service charge
    final tax = (subtotal + serviceCharge) * 0.13; // 13% tax
    final grandTotal = subtotal + serviceCharge + tax;

    final partnerName = _order?['delivery_partner']?['name'] ?? widget.deliveryPartnerName ?? 'Self Delivery';
    final customerName = _order?['customer']?['name'] ?? widget.customerName;
    String title = customerName.isNotEmpty ? "Delivery ($partnerName) • $customerName" : "Delivery ($partnerName)";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
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
                // Customer Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Customer", style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(customerName.isNotEmpty ? customerName : 'Not specified', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Items"),
                const SizedBox(height: 12),
                ..._items.map((item) => _buildItemRow(item)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow("Subtotal", "Rs ${subtotal.toStringAsFixed(0)}"),
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

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(double total) {
    if (_isPaymentReceived) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // Fix const BorderRadius error
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
        borderRadius: BorderRadius.circular(30),
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

      final success = await _tableService.processDeliveryPayment(widget.orderId, method);

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
