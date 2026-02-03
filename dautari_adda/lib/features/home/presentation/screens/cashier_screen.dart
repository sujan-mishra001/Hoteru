import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/order_service.dart';
import 'package:intl/intl.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

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
      final orders = await _orderService.getAllOrders();
      
      // Filter only unsettled orders: Pending, In Progress, or Completed
      final runningStatuses = ['Pending', 'In Progress', 'Completed'];
      final cashierOrders = (orders as List).where((order) {
        return runningStatuses.contains(order['status']);
      }).toList();
      
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

  void _showBillDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => BillDialog(order: order, onPaymentComplete: _loadOrders),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        onTap: () => _showBillDialog(order),
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
                  onPressed: () => _showBillDialog(order),
                  icon: const Icon(Icons.receipt, size: 18),
                  label: const Text('View Bill & Process Payment'),
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

// Bill Dialog Widget
class BillDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onPaymentComplete;

  const BillDialog({
    super.key,
    required this.order,
    required this.onPaymentComplete,
  });

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final subtotal = order['subtotal']?.toDouble() ?? 0.0;
    final tax = order['tax']?.toDouble() ?? 0.0;
    final discount = order['discount']?.toDouble() ?? 0.0;
    final totalAmount = order['total_amount']?.toDouble() ?? 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.black87),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bill - ${order['order_number'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Bill Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items List
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) {
                      final itemName = item['menu_item']?['name'] ?? item['item_name'] ?? '';
                      final quantity = item['quantity'] ?? 0;
                      final price = item['price']?.toDouble() ?? 0.0;
                      final itemTotal = quantity * price;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$itemName x$quantity',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              'NPR ${NumberFormat('#,##0.00').format(itemTotal)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    const Divider(height: 24),
                    
                    // Subtotal, Tax, Discount, Total
                    _buildBillRow('Subtotal', subtotal),
                    const SizedBox(height: 8),
                    _buildBillRow('Tax', tax),
                    const SizedBox(height: 8),
                    _buildBillRow('Discount', discount, isNegative: true),
                    const Divider(height: 24),
                    _buildBillRow('Total', totalAmount, isBold: true),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement print functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Print functionality coming soon')),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFFFC107)),
                        foregroundColor: const Color(0xFFFFC107),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to payment processing screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing payment...')),
                        );
                        onPaymentComplete();
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, double amount, {bool isBold = false, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}NPR ${NumberFormat('#,##0.00').format(amount)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isNegative ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}
