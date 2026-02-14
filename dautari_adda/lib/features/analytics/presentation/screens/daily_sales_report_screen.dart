import 'package:flutter/material.dart';
import 'package:dautari_adda/features/analytics/data/reports_service.dart';
import 'package:intl/intl.dart';

class DailySalesReportScreen extends StatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  State<DailySalesReportScreen> createState() => _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
  final ReportsService _reportsService = ReportsService();
  List<dynamic> _items = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final response = await _reportsService.getDailySales(
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
        title: const Text('Daily Sales Report', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    ? const Center(child: Text('No records found'))
                    : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_summary == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSummaryCard('GROSS', _summary!['gross_sales'], Colors.blue),
            _buildSummaryCard('DISCOUNT', _summary!['discount'], Colors.red),
            _buildSummaryCard('NET SALES', _summary!['net_sales'], Colors.green),
            _buildSummaryCard('PAID', _summary!['paid_sales'], Colors.teal),
            _buildSummaryCard('CREDIT', _summary!['credit_sales'], Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(
            (value ?? 0).toStringAsFixed(0),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 40,
          horizontalMargin: 12,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GROSS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('DISC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('PAID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CREDIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CASH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          rows: _items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['date'] ?? '', style: const TextStyle(fontSize: 11))),
              DataCell(Text((item['gross_total'] ?? 0).toStringAsFixed(0), style: const TextStyle(fontSize: 11))),
              DataCell(Text((item['discount'] ?? 0).toStringAsFixed(0), style: const TextStyle(fontSize: 11, color: Colors.red))),
              DataCell(Text((item['net_total'] ?? 0).toStringAsFixed(0), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              DataCell(Text((item['paid'] ?? 0).toStringAsFixed(0), style: const TextStyle(fontSize: 11, color: Colors.green))),
              DataCell(Text((item['credit_sales'] ?? 0).toStringAsFixed(0), style: const TextStyle(fontSize: 11, color: Colors.orange))),
              DataCell(Text((item['cash'] ?? 0).toStringAsFixed(0), style: const TextStyle(fontSize: 11))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
