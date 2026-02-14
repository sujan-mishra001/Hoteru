import 'package:flutter/material.dart';
import 'package:dautari_adda/features/analytics/data/reports_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'day_book_screen.dart';
import 'daily_sales_report_screen.dart';
import 'purchase_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? navigationItems;
  const ReportsScreen({super.key, this.navigationItems});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _dashboardData = await _reportsService.getDashboardSummary(
      startDate: dateStr,
      endDate: dateStr,
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handleExport(String type, String format) async {
    ToastService.show(context, "Preparing your report...");
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final bytes = await _reportsService.exportReport(
      reportType: type,
      format: format,
      startDate: dateStr,
      endDate: dateStr,
    );

    if (bytes != null) {
      await _saveAndOpenFile(bytes, "${type}_$dateStr.${format == 'pdf' ? 'pdf' : 'xlsx'}");
    } else {
      if (mounted) ToastService.show(context, "Failed to download report", isError: true);
    }
  }

  Future<void> _handleExportAll() async {
    ToastService.show(context, "Preparing Master Excel...");
    final bytes = await _reportsService.exportMasterExcel();
    if (bytes != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _saveAndOpenFile(bytes, "Master_Business_Report_$dateStr.xlsx");
    } else {
      if (mounted) ToastService.show(context, "Failed to download report", isError: true);
    }
  }

  Future<void> _saveAndOpenFile(dynamic bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      // Share the file instead of opening it directly
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Report: $fileName',
      );
      
      if (mounted) {
        ToastService.show(context, "Report saved and ready to share!");
      }
    } catch (e) {
      if (mounted) ToastService.show(context, "Error saving file: $e", isError: true);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFC107),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildActionsSection(),
                  const SizedBox(height: 20),
                  _buildSalesBreakdown(),
                  const SizedBox(height: 20),
                  _buildExportSection(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Data Intelligence",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Business performance overview",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 14, color: Colors.black87),
                  label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  onPressed: _selectDate,
                  backgroundColor: const Color(0xFFFFC107).withOpacity(0.1),
                ),
              ],
            ),
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _handleExportAll,
                icon: const Icon(Icons.download),
                label: const Text("Export All Data (Excel)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Column(
      children: [
        _buildSummaryCard(
          'Total Revenue',
          'Rs. ${(data['sales_24h'] ?? 0).toStringAsFixed(2)}',
          Icons.payments,
          Colors.green,
          isFullWidth: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              'Orders',
              '${data['orders_24h'] ?? 0}',
              Icons.shopping_bag,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Paid Sales',
              'Rs. ${(data['paid_sales'] ?? 0).toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              'Credit Sales',
              'Rs. ${(data['credit_sales'] ?? 0).toStringAsFixed(2)}',
              Icons.credit_card,
              Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Discounts',
              'Rs. ${(data['discount'] ?? 0).toStringAsFixed(2)}',
              Icons.discount,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Day Book',
                Icons.book_rounded,
                Colors.indigo,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DayBookScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Daily Sales',
                Icons.calendar_view_day_rounded,
                Colors.amber.shade800,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DailySalesReportScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Purchase',
                Icons.shopping_cart_rounded,
                Colors.teal,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseReportScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    final content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) return content;
    return Expanded(child: content);
  }

  Widget _buildSalesBreakdown() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressRow('Dine-In', data['dine_in_count'] ?? 0, Colors.blue),
            _buildProgressRow('Takeaway', data['takeaway_count'] ?? 0, Colors.orange),
            _buildProgressRow('Delivery', data['delivery_count'] ?? 0, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, Color color) {
    final total = (_dashboardData?['dine_in_count'] ?? 0) +
                  (_dashboardData?['takeaway_count'] ?? 0) +
                  (_dashboardData?['delivery_count'] ?? 0);
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              '$count orders (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExportSection() {
    final reports = [
      {
        'name': 'Daily Sales Report',
        'type': 'sales',
        'icon': Icons.calendar_today,
        'color': Colors.amber.shade800,
      },
      {
        'name': 'Purchase Report',
        'type': 'purchase',
        'icon': Icons.shopping_cart,
        'color': Colors.teal,
      },
      {
        'name': 'Inventory Report',
        'type': 'inventory',
        'icon': Icons.inventory,
        'color': Colors.orange,
      },
      {
        'name': 'Customer Data',
        'type': 'customers',
        'icon': Icons.people,
        'color': Colors.teal,
      },
      {
        'name': 'Staff Performance',
        'type': 'staff',
        'icon': Icons.group,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Reports',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              leading: Icon(report['icon'] as IconData, color: report['color'] as Color),
              title: Text(report['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    onPressed: () => _handleExport(report['type'] as String, 'pdf'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_chart, color: Colors.green, size: 20),
                    onPressed: () => _handleExport(report['type'] as String, 'excel'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
