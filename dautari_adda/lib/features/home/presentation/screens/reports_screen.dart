import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/reports_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    _dashboardData = await _reportsService.getDashboardSummary();
    setState(() => _isLoading = false);
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildSalesBreakdown(),
                  const SizedBox(height: 16),
                  _buildOrderTypeAnalysis(),
                  const SizedBox(height: 16),
                  _buildQuickStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPeriodButton('Today'),
        _buildPeriodButton('Week'),
        _buildPeriodButton('Month'),
        _buildPeriodButton('Custom'),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFFFC107) : Colors.grey[200],
        foregroundColor: isSelected ? Colors.black : Colors.black87,
      ),
      onPressed: () {
        setState(() => _selectedPeriod = period);
        _loadDashboardData();
      },
      child: Text(period),
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
              'Rs. ${(data['total_sales'] ?? 0).toStringAsFixed(2)}',
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
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesBreakdown() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
            Text(label),
            Text('$count orders (${percentage.toStringAsFixed(1)}%)'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOrderTypeAnalysis() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildOrderStat('Total Orders', data['total_orders'] ?? 0),
                _buildOrderStat('Pending', data['pending_orders'] ?? 0),
                _buildOrderStat('Completed', data['completed_orders'] ?? 0),
                _buildOrderStat('Cancelled', data['cancelled_orders'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStat(String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final data = _dashboardData;
    if (data == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_restaurant),
              title: const Text('Table Occupancy'),
              subtitle: Text('${data['occupancy']?.toStringAsFixed(1) ?? 0}%'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to table management
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Total Customers'),
              subtitle: Text('${data['total_customers'] ?? 0}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to customers
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Average Order Value'),
              subtitle: Text('Rs. ${(data['avg_order_value'] ?? 0).toStringAsFixed(2)}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to detailed reports
              },
            ),
          ],
        ),
      ),
    );
  }
}
