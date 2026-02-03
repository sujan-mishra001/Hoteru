import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/reports_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

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
        title: const Text('Reports & Analytics'),
        backgroundColor: const Color(0xFFFFC107),
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
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildSalesBreakdown(),
                  const SizedBox(height: 24),
                  _buildExportSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Intelligence Center",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Business analytics & reports",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFFFC107)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleExportAll,
              icon: const Icon(Icons.table_chart_rounded),
              label: Text("Export Master Excel", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              'Total Sales',
              'Rs. ${(data['sales_24h'] ?? 0).toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Paid Sales',
              'Rs. ${(data['paid_sales'] ?? 0).toStringAsFixed(2)}',
              Icons.check_circle,
              Colors.blue,
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
              Icons.local_offer,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesBreakdown() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Breakdown',
            style: GoogleFonts.poppins(
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
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              '$count orders (${percentage.toStringAsFixed(1)}%)',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
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
            minHeight: 6,
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
        'icon': Icons.attach_money_rounded,
        'color': Colors.blue,
        'desc': 'Sales, tax, and discount summary'
      },
      {
        'name': 'Inventory Consumption',
        'type': 'inventory',
        'icon': Icons.inventory_2_rounded,
        'color': Colors.orange,
        'desc': 'Track stock and material usage'
      },
      {
        'name': 'Customer Analytics',
        'type': 'customers',
        'icon': Icons.people_alt_rounded,
        'color': Colors.teal,
        'desc': 'Customer spending and visits'
      },
      {
        'name': 'Staff Performance',
        'type': 'staff',
        'icon': Icons.emoji_events_rounded,
        'color': Colors.purple,
        'desc': 'Duty and order performance'
      },
      {
        'name': 'Session Report',
        'type': 'sessions',
        'icon': Icons.history_rounded,
        'color': Colors.blueGrey,
        'desc': 'All POS sessions and staff activity'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Data Exports',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 140,
            mainAxisSpacing: 16,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report);
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (report['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(report['icon'], color: report['color'], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['name'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      report['desc'],
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleExport(report['type'], 'pdf'),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: Text("PDF", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red.shade100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (report['type'] != 'sessions')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleExport(report['type'], 'excel'),
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: Text("Excel", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green.shade100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
