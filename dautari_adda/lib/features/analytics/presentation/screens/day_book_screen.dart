import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/data/order_service.dart';
import 'package:intl/intl.dart';

class DayBookScreen extends StatefulWidget {
  const DayBookScreen({super.key});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  final OrderService _orderService = OrderService();
  
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  
  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDayBook();
  }

  Future<void> _loadDayBook() async {
    setState(() => _isLoading = true);
    try {
      // Load orders for selected date
      final orders = await _orderService.getAllOrders();
      
      final List<Map<String, dynamic>> dayTransactions = [];
      double income = 0.0;
      double expense = 0.0;
      
      // Filter orders by selected date
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      for (var order in orders) {
        final orderDate = order['created_at'] != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(order['created_at']))
            : '';
        
        if (orderDate == selectedDateStr) {
          final amount = order['total_amount']?.toDouble() ?? 0.0;
          final isPaid = order['payment_status'] == 'Paid' || order['status'] == 'Settled';
          
          if (isPaid) {
            income += amount;
            dayTransactions.add({
              'type': 'income',
              'description': 'Order ${order['order_number']}',
              'amount': amount,
              'time': order['created_at'],
              'category': order['order_type'] ?? 'dine_in',
              'payment_mode': order['payment_mode'] ?? 'Cash',
            });
          }
        }
      }
      
      // TODO: Add expense transactions from expenses API when available
      
      setState(() {
        _transactions = dayTransactions;
        _totalIncome = income;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading day book: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDayBook();
    }
  }

  Color _getTransactionColor(String type) {
    return type == 'income' ? const Color(0xFF10b981) : const Color(0xFFef4444);
  }

  IconData _getTransactionIcon(String type) {
    return type == 'income' ? Icons.arrow_downward : Icons.arrow_upward;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Book'),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDayBook,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Color(0xFFFFC107)),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Income',
                    _totalIncome,
                    const Color(0xFF10b981),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),
          
          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No transactions for this date',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat('#,##0').format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'income';
    final description = transaction['description'] ?? '';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final time = transaction['time'] != null 
        ? DateTime.parse(transaction['time'])
        : DateTime.now();
    final category = transaction['category'] ?? '';
    final paymentMode = transaction['payment_mode'] ?? '';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getTransactionColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTransactionIcon(type),
                color: _getTransactionColor(type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(time),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: Colors.grey)),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (paymentMode.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: Colors.grey)),
                        Text(
                          paymentMode,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${type == 'expense' ? '-' : '+'}NPR ${NumberFormat('#,##0.00').format(amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getTransactionColor(type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
