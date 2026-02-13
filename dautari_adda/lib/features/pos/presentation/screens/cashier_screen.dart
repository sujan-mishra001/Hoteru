import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';
import 'package:dautari_adda/features/pos/data/order_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/data/session_service.dart';
import 'package:dautari_adda/features/analytics/data/reports_service.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';
import 'package:intl/intl.dart';

class CashierScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? navigationItems;
  final Function(int)? onTabChange;
  const CashierScreen({super.key, this.navigationItems, this.onTabChange});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final TableService _tableService = TableService();
  final SessionService _sessionService = SessionService();
  final ReportsService _reportsService = ReportsService();
  final ReportsService _reportsService = ReportsService();
  late TabController _tabController;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  double _todayOpening = 0;
  double _todaySales = 0;
  double _yesterdaySales = 0;
  int _yesterdayOrders = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
    _loadSalesSummary();
    _searchController.addListener(_filterOrders);
  }

  Future<void> _loadSalesSummary() async {
    try {
      // Fetch opening cash from session
      final session = await _sessionService.getActiveSession();
      if (session != null) {
        _todayOpening = (session['opening_cash'] as num?)?.toDouble() ?? 0;
      }

      // Fetch today's sales from reports
      final dashboard = await _reportsService.getDashboardSummary();
      if (dashboard != null) {
        _todaySales = (dashboard['sales_24h'] as num?)?.toDouble() ?? 0;
      }

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayFormatted = DateFormat('yyyy-MM-dd').format(yesterday);
      final yesterdayData = await _sessionService.getSalesForDate(yesterday);
      
      if (yesterdayData != null) {
        _yesterdaySales = (yesterdayData['sales_24h'] as num?)?.toDouble() ?? 0;
        _yesterdayOrders = (yesterdayData['orders_24h'] as num?)?.toInt() ?? 0;
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading sales summary: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // Fetch tables for merge_group_id mapping (needed for merged table grouping)
      await _tableService.fetchTables();
      final tables = _tableService.tables;

      // Build table id -> merge_group_id map
      final Map<int, dynamic> tableIdToMergeGroup = {};
      final Map<dynamic, List<PosTable>> mergeGroupToTables = {};
      for (final t in tables) {
        if (t.mergeGroupId != null) {
          tableIdToMergeGroup[t.id] = t.mergeGroupId;
          mergeGroupToTables.putIfAbsent(t.mergeGroupId, () => []).add(t);
        }
      }

      // Fetch orders that need payment (exclude Paid and Completed orders)
      final orders = await _orderService.getOrders(
        status: 'Pending,Draft,InProgress,BillRequested'
      );

      // Group orders by table or merge_group; accumulate amounts
      final Map<Object, List<Map<String, dynamic>>> ordersByKey = {};
      final Map<Object, double> totalsByKey = {};

      for (var order in orders) {
        final tableId = order['table_id'] as int? ?? 0;
        final orderType = (order['order_type'] ?? '').toString().toLowerCase();
        final amt = (order['total_amount'] ?? order['net_amount'] ?? 0.0) as num;
        final amount = amt is int ? amt.toDouble() : (amt as double);

        Object key;
        if (tableId <= 0) {
          // Separate takeaway and delivery by order_type and customer
          final customerId = order['customer_id'];
          if (orderType == 'takeaway') {
            // Group takeaway orders by customer_id, or order_id if no customer
            key = customerId != null ? 'takeaway_customer_$customerId' : 'takeaway_order_${order['id']}';
          } else if (orderType.contains('delivery')) {
            // Group delivery orders by customer_id and delivery_partner_id
            final deliveryPartnerId = order['delivery_partner_id'];
            if (customerId != null) {
              key = deliveryPartnerId != null 
                  ? 'delivery_customer_${customerId}_partner_$deliveryPartnerId'
                  : 'delivery_customer_$customerId';
            } else {
              key = deliveryPartnerId != null ? 'delivery_partner_$deliveryPartnerId' : 'delivery_order_${order['id']}';
            }
          } else {
            key = 'other_$tableId';
          }
        } else {
          // Table orders - group by merge_group_id or table_id
          final mgId = tableIdToMergeGroup[tableId];
          key = mgId ?? tableId;
        }

        ordersByKey.putIfAbsent(key, () => []).add(order);
        totalsByKey[key] = (totalsByKey[key] ?? 0.0) + amount;
      }

      // Convert to list with accumulated data
      final List<Map<String, dynamic>> accumulatedOrders = [];
      ordersByKey.forEach((key, tableOrders) {
        if (tableOrders.isEmpty) return;
        final firstOrder = tableOrders.first;
        final tableId = firstOrder['table_id'] as int? ?? 0;

        String displayName;
        final orderTypeStr = (firstOrder['order_type'] ?? '').toString().toLowerCase();
        final keyStr = key.toString();
        if (keyStr.startsWith('takeaway')) {
          final customerName = firstOrder['customer']?['name']?.toString();
          displayName = customerName != null && customerName.isNotEmpty ? 'Takeaway • $customerName' : 'Takeaway';
        } else if (keyStr.startsWith('delivery')) {
          final deliveryPartner = firstOrder['delivery_partner'];
          final partnerName = deliveryPartner?['name']?.toString() ?? 'Self Delivery';
          displayName = 'Delivery ($partnerName)';
        } else if (mergeGroupToTables.containsKey(key)) {
          final mgTables = mergeGroupToTables[key]!;
          final names = mgTables.map((t) => t.tableId).toList();
          displayName = 'Merged: ${names.join(', ')}';
        } else {
          final t = tables.where((tbl) => tbl.id == tableId).firstOrNull;
          displayName = tableId > 0 ? (t?.tableId ?? 'Table $tableId') : 'Unknown';
        }

        accumulatedOrders.add({
          ...firstOrder,
          'table_id': tableId,
          'total_amount': totalsByKey[key],
          'order_count': tableOrders.length,
          'orders': tableOrders,
          'display_name': displayName,
        });
      });

      setState(() {
        _orders = accumulatedOrders;
        _filteredOrders = accumulatedOrders;
        _isLoading = false;
      });
      _loadSalesSummary();
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
    if (type == null) return 'Unknown';
    final typeLower = type.toLowerCase();
    if (typeLower == 'table' || typeLower == 'dine_in' || typeLower == 'dine-in') {
      return 'Dine In';
    } else if (typeLower == 'takeaway') {
      return 'Takeaway';
    } else if (typeLower.contains('delivery')) {
      return 'Delivery';
    }
    return type;
  }

  void _navigateToPayment(Map<String, dynamic> order) async {
    // If this is an accumulated order with multiple orders, navigate with all orders
    final List<Map<String, dynamic>> ordersToPay = order['orders'] ?? [order];
    final tableId = order['table_id'] as int? ?? 0;
    final orderType = order['order_type'];
    final customer = order['customer'];
    final customerName = customer?['name'] as String?;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillScreen(
          tableNumber: tableId,
          orderId: order['id'],
          navigationItems: widget.navigationItems,
          accumulatedOrders: ordersToPay,
          tableDisplayName: order['display_name'] as String?,
          orderType: orderType,
          customerName: customerName,
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
        toolbarHeight: 120,
        title: Column(
          children: [
            Row(
              children: [
                Text(
                  'Cashier',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.black87,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Dine-in'),
                Tab(text: 'Takeaway'),
                Tab(text: 'Delivery'),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actionsIconTheme: const IconThemeData(color: Colors.black54),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's & Yesterday's summary boxes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    height: 85, // Reduced height to fix overflow
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Today\'s Sale', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('NPR ${NumberFormat('#,##0').format(_todaySales)}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('Opening', style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54)),
                        Text('NPR ${NumberFormat('#,##0').format(_todayOpening)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    height: 85, // Reduced height to fix overflow
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Yesterday\'s Sale', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('NPR ${NumberFormat('#,##0').format(_yesterdaySales)}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('Total Orders', style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54)),
                        Text('$_yesterdayOrders orders', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList('dine-in'),
                      _buildOrdersList('takeaway'),
                      _buildOrdersList('delivery'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String type) {
    final filtered = _filteredOrders.where((order) {
      final orderType = (order['order_type'] ?? '').toString().toLowerCase();
      if (type == 'dine-in') return orderType == 'table' || orderType == 'dine-in';
      if (type == 'takeaway') return orderType == 'takeaway';
      if (type == 'delivery') return orderType.contains('delivery');
      return false;
    }).toList();

    final totalAmount = filtered.fold<double>(0, (sum, order) => sum + (order['total_amount'] ?? 0));

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No current $type orders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.blueGrey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Pending (${filtered.length})",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.blueGrey),
              ),
              Text(
                "NPR ${NumberFormat('#,##0').format(totalAmount)}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final order = filtered[index];
              return _buildOrderCard(order);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNumber = order['order_number'] ?? '';
    final orderType = _getOrderType(order['order_type']);
    final status = order['status'] ?? '';
    final totalAmount = order['total_amount']?.toDouble() ?? 0.0;
    final orderCount = order['order_count'] ?? 1;
    final createdAt = order['created_at'] != null 
        ? DateTime.parse(order['created_at'])
        : DateTime.now();
    final tableName = order['display_name'] ?? order['table']?['table_id'] ?? 'Unknown';
    final orderTypeStr = (order['order_type'] ?? '').toString().toLowerCase();
    final customer = order['customer'];
    final customerName = customer?['name'] ?? (orderTypeStr.contains('delivery') ? '' : 'Walk-in');
    final customerName = orderType == 'Delivery' ? null : (customer?['name'] ?? 'Walk-in');
    final deliveryPartner = order['delivery_partner'];
    final partnerName = deliveryPartner?['name'];

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
                          tableName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (orderCount > 1)
                          Text(
                            '$orderCount orders',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
                        if (orderNumber.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.receipt, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                orderNumber,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (customerName.isNotEmpty || partnerName != null)
                        Row(
                          children: [
                            if (customerName.isNotEmpty) ...[
                              const Icon(Icons.person, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                customerName,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            if (partnerName != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.delivery_dining, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                partnerName,
                                style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                              ),
                            ],
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
                  Text(
                    'Total Amount (${orderCount} orders):',
                    style: const TextStyle(
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
