import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:dautari_adda/features/pos/data/table_service.dart';

class BillScreen extends StatelessWidget {
  final int tableNumber;
  final List<Map<String, dynamic>>? navigationItems;

  const BillScreen({super.key, required this.tableNumber, this.navigationItems});

  Future<void> _printBill(BuildContext context, int tableNumber, List<CartItem> cart, double total, TableService tableService) async {
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
                          pw.Text('Table: ${tableService.getTableName(tableNumber)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
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
                    pw.Text('Service Charge (${tableService.serviceChargeRate.toStringAsFixed(0)}%):', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Rs ${tableService.getServiceCharge(tableNumber).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                 ]
               ),
               if (tableService.taxRate > 0)
                 pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                      pw.Text('Tax (${tableService.taxRate.toStringAsFixed(0)}%):', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Rs ${tableService.getTaxAmount(tableNumber).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                   ]
                 ),
               pw.Divider(),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Rs ${tableService.getNetTotal(tableNumber).toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
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
    final tableService = TableService();
    return ListenableBuilder(
      listenable: tableService,
      builder: (context, child) {
        final cart = tableService.getCart(tableNumber);
        final total = tableService.getTableTotal(tableNumber);
        final isBooked = tableService.isTableBooked(tableNumber);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Bill Overview • ${tableService.getTableName(tableNumber)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            backgroundColor: const Color(0xFFFFC107),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.print_rounded, color: Colors.black87),
                tooltip: "Print Bill",
                onPressed: () => _printBill(context, tableNumber, cart, total, tableService),
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
                              Text("Service Charge (${tableService.serviceChargeRate.toStringAsFixed(0)}%)", style: TextStyle(color: Colors.grey[600])),
                              Text("Rs ${tableService.getServiceCharge(tableNumber).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (tableService.taxRate > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Tax (${tableService.taxRate.toStringAsFixed(0)}%)", style: TextStyle(color: Colors.grey[600])),
                                Text("Rs ${tableService.getTaxAmount(tableNumber).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                "Rs ${tableService.getNetTotal(tableNumber).toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (isBooked) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _PaymentDialog(
                                      tableNumber: tableNumber, 
                                      total: total, 
                                      cart: cart,
                                      tableService: tableService
                                    ),
                                  );
                                } else if (cart.isNotEmpty) {
                                  final success = await tableService.confirmOrder(tableNumber, cart);
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Table Booked Successfully!"),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBooked ? Colors.green : const Color(0xFFFFC107),
                                foregroundColor: isBooked ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(
                                isBooked ? "Proceed to Payment" : "Confirm Order & Book",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
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
              items: navigationItems != null
                  ? navigationItems!.map((item) {
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

  const _PaymentDialog({
    required this.tableNumber,
    required this.total,
    required this.cart,
    required this.tableService,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {

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
