import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dautari_adda/features/home/data/table_service.dart';

enum DateFilter { all, today, month }

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateFilter _selectedFilter = DateFilter.all;
  String _selectedPaymentMethod = "All";

  List<BillRecord> _getFilteredBills(List<BillRecord> allBills) {
    List<BillRecord> filtered = allBills;

    // 1. Filter by Date
    final now = DateTime.now();
    if (_selectedFilter == DateFilter.today) {
      filtered = filtered.where((bill) {
        return bill.date.year == now.year &&
               bill.date.month == now.month &&
               bill.date.day == now.day;
      }).toList();
    } else if (_selectedFilter == DateFilter.month) {
      filtered = filtered.where((bill) {
        return bill.date.year == now.year &&
               bill.date.month == now.month;
      }).toList();
    }

    // 2. Filter by Payment Method
    if (_selectedPaymentMethod != "All") {
      filtered = filtered.where((bill) => bill.paymentMethod.toLowerCase().contains(_selectedPaymentMethod.toLowerCase())).toList();
    }

    return filtered;
  }

  double _calculateTotal(List<BillRecord> bills) {
    return bills.fold(0, (sum, bill) => sum + bill.amount);
  }

  Future<void> _printBill(BuildContext context, int tableNumber, List<CartItem> cart, double total, DateTime date) async {
    final doc = pw.Document();
    
    // Calculate total quantity
    int totalQty = cart.fold(0, (sum, item) => sum + item.quantity);

    // Get User Name from local caching or service
    String userName = "Staff";
    
    // Random KOT or similar ID
    final kotNo = Random().nextInt(90) + 10; 

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                          pw.Text('Table: T$tableNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.SizedBox(height: 2),
                          pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(date)}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('User: $userName', style: pw.TextStyle(fontSize: 10)),
                       ]
                     ),
                     pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.end,
                       children: [
                          pw.Text('KOT No: $kotNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.SizedBox(height: 2),
                          pw.Text('Time: ${DateFormat('hh:mm a').format(date)}', style: const pw.TextStyle(fontSize: 10)),
                       ]
                     )
                  ]
               ),
               pw.SizedBox(height: 10),
               
               pw.Row(
                 children: [
                    pw.Expanded(child: pw.Text('Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                    pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                 ]
               ),
               pw.Divider(thickness: 1), 

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
               
               pw.SizedBox(height: 10),
               pw.Divider(),
               
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                    pw.Text('Total Qty: $totalQty', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.Text('Total: Rs ${total.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                 ]
               ),
               pw.SizedBox(height: 10),
               pw.Center(
                 child: pw.Text('--- Re-printed Receipt ---', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
               ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> _printAllBills(List<BillRecord> bills, double totalAmount) async {
    final doc = pw.Document();
    
    // Get User Name from local caching or service
    String userName = "Staff";

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('DAUTARI ADDA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('REPORT SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Printed: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                  ]
                )
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Date/Table', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(flex: 2, child: pw.Text('Method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(flex: 2, child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                ]
              ),
              pw.Divider(thickness: 0.5),
              ...bills.map((bill) => pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 3, 
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(DateFormat('MM/dd').format(bill.date), style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('Table ${bill.tableNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ]
                      )
                    ),
                    pw.Expanded(flex: 2, child: pw.Text(bill.paymentMethod, style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 2, child: pw.Text('Rs ${bill.amount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                  ]
                ),
              )),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Count: ${bills.length}', style: const pw.TextStyle(fontSize: 9)),
                   pw.Text('Total: Rs ${totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ]
              ),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text('Printed by: $userName', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ),
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Bills & Expenses",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: "Print All",
            onPressed: () {
              final allBills = tableService.pastBills;
              final filteredBills = _getFilteredBills(allBills);
              final totalAmount = _calculateTotal(filteredBills);
              if (filteredBills.isNotEmpty) {
                _printAllBills(filteredBills, totalAmount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No bills to print")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Refreshed"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: tableService,
        builder: (context, _) {
          final allBills = tableService.pastBills;
          final filteredBills = _getFilteredBills(allBills);
          final totalAmount = _calculateTotal(filteredBills);

          return Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rs ${totalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "${filteredBills.length} Bills",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Date Filters
                    Row(
                      children: [
                        _buildFilterTab("All Time", DateFilter.all),
                        const SizedBox(width: 8),
                        _buildFilterTab("Today", DateFilter.today),
                        const SizedBox(width: 8),
                        _buildFilterTab("This Month", DateFilter.month),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Payment Method Filter
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPaymentMethod,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFC107)),
                                items: ["All", "Cash", "QR"].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Icon(
                                          value == "Cash" ? Icons.money : 
                                          value == "QR" ? Icons.qr_code : 
                                          Icons.payment,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(value),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedPaymentMethod = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Bills List
              Expanded(
                child: filteredBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allBills.isEmpty ? "No Bills Yet" : "No Bills Match Filter",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (allBills.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "${allBills.length} total bills available",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBills.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bill = filteredBills[index];
                          return _buildBillCard(bill);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String label, DateFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(BillRecord bill) {
    final isCash = bill.paymentMethod.toLowerCase().contains('cash');
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCash ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCash ? Icons.money : Icons.qr_code,
                    color: isCash ? Colors.green : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Table ${bill.tableNumber}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(bill.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isCash ? Colors.green.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bill.paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCash ? Colors.green.shade700 : Colors.blue.shade700,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${bill.items.length} items",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.print_rounded, size: 20, color: Colors.black54),
                  onPressed: () => _printBill(context, bill.tableNumber, bill.items, bill.amount, bill.date),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),

            // Items List (max 3)
            ...bill.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${item.quantity}×",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.menuItem.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "Rs ${item.totalPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),

            if (bill.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  "and ${bill.items.length - 3} more...",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),

            // Footer - Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Rs ${bill.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC107),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
