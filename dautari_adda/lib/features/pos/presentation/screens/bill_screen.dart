import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/data/menu_data.dart';

class BillScreen extends StatefulWidget {
  final int tableNumber;
  final List<Map<String, dynamic>>? navigationItems;

  const BillScreen({super.key, required this.tableNumber, this.navigationItems});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final TableService _tableService = TableService();
  bool _isLoadingOrder = true;
  Map<String, dynamic>? _existingOrder;
  List<CartItem> _displayCart = [];
  bool _hasExistingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadExistingOrder();
  }

  Future<void> _loadExistingOrder() async {
    setState(() => _isLoadingOrder = true);
    
    try {
      final orderData = await _tableService.getActiveOrderForTable(widget.tableNumber);
      
      if (orderData != null && mounted) {
        setState(() {
          _existingOrder = orderData;
          _hasExistingOrder = true;
          
          // Convert backend order items to CartItem format for display
          if (orderData['items'] != null) {
            _displayCart = (orderData['items'] as List).map((item) {
              return CartItem(
                menuItem: MenuItem(
                  id: item['menu_item_id'],
                  name: item['menu_item']?['name'] ?? 'Unknown Item',
                  price: (item['price'] as num).toDouble(),
                  category: '',
                  image: '',
                ),
                quantity: item['quantity'],
              );
            }).toList();
          }
        });
      } else if (mounted) {
        // No existing order, use local cart
        setState(() {
          _hasExistingOrder = false;
          _displayCart = _tableService.getCart(widget.tableNumber);
        });
      }
    } catch (e) {
      debugPrint("Error loading existing order: $e");
      if (mounted) {
        setState(() {
          _hasExistingOrder = false;
          _displayCart = _tableService.getCart(widget.tableNumber);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOrder = false);
      }
    }
  }

  Future<void> _printBill(BuildContext context, int tableNumber, List<CartItem> cart, double total) async {
    final doc = pw.Document();
    
    // Calculate total quantity
    int totalQty = cart.fold(0, (sum, item) => sum + item.quantity);

    // Get User Name from local caching or service
    String userName = "Staff";
    
    // Random KOT
    final kotNo = Random().nextInt(90) + 10; // 10 to 99

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5), // Small margin for thermal
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               // Header Row 1
               pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                          pw.Text('Table: ${_tableService.getTableName(tableNumber)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.SizedBox(height: 2),
                          pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('User: $userName', style: const pw.TextStyle(fontSize: 10)),
                       ]
                     ),
                     pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.end,
                       children: [
                          pw.Text('KOT No: $kotNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.SizedBox(height: 2),
                          pw.Text('Time: ${DateFormat('hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                       ]
                     )
                  ]
               ),
               pw.SizedBox(height: 10),
               
               // Items Header
               pw.Row(
                 children: [
                    pw.Expanded(child: pw.Text('Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                    pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                 ]
               ),
               pw.Divider(thickness: 1), // Line under header

               // Items List
               ...cart.map((item) => pw.Container(
                 margin: const pw.EdgeInsets.symmetric(vertical: 2),
                 child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        item.menuItem.name, 
                        style: const pw.TextStyle(fontSize: 10)
                      )
                    ),
                    pw.Text(
                      item.quantity.toString(),
                      style: const pw.TextStyle(fontSize: 10)
                    ),
                  ]
                 )
               )),
               
                pw.SizedBox(height: 5),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Rs ${total.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                 ]
               ),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    pw.Text('Service Charge (${_tableService.serviceChargeRate.toStringAsFixed(0)}%):', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Rs ${_tableService.getServiceCharge(tableNumber).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                 ]
               ),
               if (_tableService.taxRate > 0)
                 pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                      pw.Text('Tax (${_tableService.taxRate.toStringAsFixed(0)}%):', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Rs ${_tableService.getTaxAmount(tableNumber).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                   ]
                 ),
               pw.Divider(),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Rs ${_tableService.getNetTotal(tableNumber).toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                 ]
               ),
               pw.SizedBox(height: 10),
               
               // Footer
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    pw.Text('Total Qty: $totalQty', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                    pw.Text('Thank you!', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                 ]
               ),
               pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tableService,
      builder: (context, child) {
        // Use display cart (either from backend order or local cart)
        final cart = _displayCart;
        final total = cart.fold(0.0, (sum, item) => sum + item.totalPrice);
        final isBooked = _hasExistingOrder || _tableService.isTableBooked(widget.tableNumber);

        if (_isLoadingOrder) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Bill Overview • ${_tableService.getTableName(widget.tableNumber)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
              backgroundColor: const Color(0xFFFFC107),
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Bill Overview • ${_tableService.getTableName(widget.tableNumber)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            backgroundColor: const Color(0xFFFFC107),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.print_rounded, color: Colors.black87),
                tooltip: "Print Bill",
                onPressed: cart.isEmpty ? null : () => _printBill(context, widget.tableNumber, cart, total),
              ),
            ],
          ),
          body: cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        "No items ordered yet.",
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Enhanced Status Header
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isBooked ? Colors.red : Colors.green).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isBooked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                color: isBooked ? Colors.red : Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Table Status: ${isBooked ? "BOOKED" : "OPEN"}",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: isBooked ? Colors.red : Colors.green,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // List of items
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.restaurant_rounded, color: Colors.grey, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.menuItem.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Rs ${item.menuItem.price} × ${item.quantity}",
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "Rs ${item.totalPrice.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Summary Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Subtotal", style: TextStyle(color: Colors.grey[600])),
                              Text("Rs ${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Service Charge (${_tableService.serviceChargeRate.toStringAsFixed(0)}%)", style: TextStyle(color: Colors.grey[600])),
                              Text("Rs ${_tableService.getServiceCharge(widget.tableNumber).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_tableService.taxRate > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Tax (${_tableService.taxRate.toStringAsFixed(0)}%)", style: TextStyle(color: Colors.grey[600])),
                                Text("Rs ${_tableService.getTaxAmount(widget.tableNumber).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Payable",
                                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "Rs ${_tableService.getNetTotal(widget.tableNumber).toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Action Button
                          if (_hasExistingOrder) ...[
                            // Table already has an order - only allow payment
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _PaymentDialog(
                                      tableNumber: widget.tableNumber, 
                                      total: total, 
                                      cart: cart,
                                      tableService: _tableService,
                                      existingOrderId: _existingOrder?['id'],
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Proceed to Payment",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "⚠️ This table already has an active order. You can only complete payment.",
                              style: TextStyle(fontSize: 13, color: Colors.orange[700], fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            // No existing order - allow booking
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: cart.isEmpty ? null : () async {
                                  final success = await _tableService.confirmOrder(widget.tableNumber, cart);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Table Booked Successfully!"),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Reload to show updated state
                                    await _loadExistingOrder();
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Failed to book table. Please try again."),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC107),
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Confirm Order & Book",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
              onTap: (index) => Navigator.pop(context, index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFFFFC107),
              unselectedItemColor: Colors.grey[400],
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 0,
              items: widget.navigationItems != null
                  ? widget.navigationItems!.map((item) {
                      return BottomNavigationBarItem(
                        icon: Icon(item['icon'] as IconData),
                        label: item['label'] as String,
                      );
                    }).toList()
                  : const [
                      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
                      BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
                      BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
                      BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Expenses'),
                    ],
                ),
              ),
        );
      },
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final int tableNumber;
  final double total;
  final List<CartItem> cart;
  final TableService tableService;
  final int? existingOrderId;

  const _PaymentDialog({
    required this.tableNumber,
    required this.total,
    required this.cart,
    required this.tableService,
    this.existingOrderId,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final ApiService _apiService = ApiService();
  List<dynamic> _qrCodes = [];
  bool _loadingQRs = false;

  @override
  void initState() {
    super.initState();
    _fetchQRCodes();
  }

  Future<void> _fetchQRCodes() async {
    setState(() => _loadingQRs = true);
    try {
      final response = await _apiService.get('/qr-codes?is_active=true');
      if (response.statusCode == 200) {
        setState(() => _qrCodes = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error fetching QR codes: $e");
    } finally {
      setState(() => _loadingQRs = false);
    }
  }

  void _showQRSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select QR Provider"),
        content: _loadingQRs 
          ? const Center(child: CircularProgressIndicator())
          : _qrCodes.isEmpty
            ? const Text("No QR codes configured. Please add them in settings.")
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _qrCodes.length,
                  itemBuilder: (context, index) {
                    final qr = _qrCodes[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code),
                      title: Text(qr['name']),
                      onTap: () {
                        Navigator.pop(context);
                        _showLargeQR(qr);
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ],
      ),
    );
  }

  void _showLargeQR(dynamic qr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(qr['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: Image.network(
                    "${ApiService.baseHostUrl}${qr['image_url']}",
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processPayment("QR Pay (${qr['name']})");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Confirm Payment Received", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment(String method) async {
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Processing payment..."), duration: Duration(seconds: 1)),
      );
    }
    
    final success = await widget.tableService.addBill(widget.tableNumber, widget.cart, method);
    
    if (success) {
      widget.tableService.clearTable(widget.tableNumber);
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close Bill Screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ Paid with $method & Table Cleared"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠ Error saving bill. Please check backend connection."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Payment Confirmation"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Payment Method:"),
              const SizedBox(height: 16),
              
              // CASH Option
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _processPayment("Cash"), 
                  icon: const Icon(Icons.money),
                  label: const Text("Pay with Cash"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // QR Option
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showQRSelectionDialog(), 
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text("Pay with QR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
               SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _processPayment("Card"), 
                  icon: const Icon(Icons.credit_card),
                  label: const Text("Pay with Card"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
