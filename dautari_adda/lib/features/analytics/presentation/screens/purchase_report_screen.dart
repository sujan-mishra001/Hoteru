import 'package:flutter/material.dart';
import 'package:dautari_adda/features/analytics/data/reports_service.dart';
import 'package:intl/intl.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  final ReportsService _reportsService = ReportsService();
  List<dynamic> _items = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final response = await _reportsService.getPurchaseReport(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    
    setState(() {
      if (response != null) {
        _items = response['items'] ?? [];
        _summary = response['summary'];
      }
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Purchase Report', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _selectDateRange),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildSummarySection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : _items.isEmpty
                    ? const Center(child: Text('No purchase records found'))
                    : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_summary == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildSummaryCard(
            'TOTAL BILLS',
            '${_summary!['total_bills'] ?? 0}',
            Colors.indigo,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'TOTAL PAYABLE',
            'Rs. ${(_summary!['total_payable'] ?? 0).toStringAsFixed(2)}',
            Colors.red,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'TOTAL PAID',
            'Rs. ${(_summary!['total_paid'] ?? 0).toStringAsFixed(2)}',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(
              value is String ? value : value.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 45,
          horizontalMargin: 12,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('BILL #', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SUPPLIER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('PAYABLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('PAID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          rows: _items.map((item) {
            final status = (item['status'] ?? 'Pending').toString().toUpperCase();
            final isPaid = status == 'PAID';
            return DataRow(cells: [
              DataCell(Text(item['bill_number'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              DataCell(Text(item['date'] ?? '', style: const TextStyle(fontSize: 11))),
              DataCell(Text(item['supplier_name'] ?? 'N/A', style: const TextStyle(fontSize: 11))),
              DataCell(Text('Rs. ${(item['payable'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
              DataCell(Text(
                'Rs. ${(item['paid'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Colors.green),
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
