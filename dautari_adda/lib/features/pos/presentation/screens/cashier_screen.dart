import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';
import 'package:dautari_adda/features/pos/data/order_service.dart';
import 'package:intl/intl.dart';

class CashierScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? navigationItems;
  final Function(int)? onTabChange;
  const CashierScreen({super.key, this.navigationItems, this.onTabChange});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final OrderService _orderService = OrderService();
  
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // Fetch orders that need payment
      final orders = await _orderService.getOrders(
        status: 'Pending,Draft,InProgress,BillRequested,Completed'
      );
      
      final cashierOrders = orders;
      
      setState(() {
        _orders = cashierOrders.cast<Map<String, dynamic>>();
        _filteredOrders = _orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _orders.where((order) {
        final orderNumber = (order['order_number'] ?? '').toString().toLowerCase();
        final customerName = (order['customer']?['name'] ?? '').toString().toLowerCase();
        return orderNumber.contains(query) || customerName.contains(query);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFf59e0b);
      case 'In Progress':
        return const Color(0xFF3b82f6);
      case 'Completed':
        return const Color(0xFF10b981);
      default:
        return Colors.grey;
    }
  }

  String _getOrderType(String? type) {
    switch (type) {
      case 'dine_in':
        return 'Dine In';
      case 'takeaway':
        return 'Takeaway';
      case 'delivery':
        return 'Delivery';
      default:
        return 'Unknown';
    }
  }

  void _navigateToPayment(Map<String, dynamic> order) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => BillScreen(
          tableNumber: order['table_id'] ?? 0,
          orderId: order['id'],
          navigationItems: widget.navigationItems,
        ),
      ),
    );
    if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Text('Cashier'),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No orders found for cashier',
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
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNumber = order['order_number'] ?? '';
    final orderType = _getOrderType(order['order_type']);
    final status = order['status'] ?? '';
    final totalAmount = order['total_amount']?.toDouble() ?? 0.0;
    final createdAt = order['created_at'] != null 
        ? DateTime.parse(order['created_at'])
        : DateTime.now();
    final tableName = order['table']?['table_id'] ?? '';
    final customerName = order['customer']?['name'] ?? 'Walk-in';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPayment(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              orderType == 'Dine In' 
                                  ? Icons.restaurant 
                                  : orderType == 'Takeaway'
                                      ? Icons.shopping_basket
                                      : Icons.delivery_dining,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              orderType,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tableName.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.table_restaurant, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                tableName,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              customerName,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'NPR ${NumberFormat('#,##0.00').format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10b981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToPayment(order),
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Proceed to Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
