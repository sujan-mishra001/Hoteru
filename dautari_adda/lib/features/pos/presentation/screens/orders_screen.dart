import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/data/order_service.dart';
import 'package:dautari_adda/features/pos/presentation/widgets/horizontal_swipe_hit_test_filter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'order_overview_screen.dart'; // Changed from bill_screen.dart

enum OrderStatus { all, dineIn, takeaway, delivery, drafts }

class OrdersScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? navigationItems;
  final Function(int)? onTabChange;
  const OrdersScreen({super.key, this.navigationItems, this.onTabChange});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<dynamic> _backendOrders = [];
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isFetching = true);
    try {
      final orders = await _orderService.getAllOrders();
      if (!mounted) return;
      setState(() {
        _backendOrders = orders;
        _isFetching = false;
      });
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (!mounted) return;
      setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableService = TableService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Orders Management",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.black54),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: ListenableBuilder(
            listenable: tableService,
            builder: (context, _) {
              final activeTableIds = tableService.activeTableIds;
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "LIVE OPERATIONS",
                                style: GoogleFonts.poppins(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              Text(
                                "${activeTableIds.length} tables require attention",
                                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), shape: BoxShape.circle),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.black87, size: 20),
                        ),
                      ],
                    ),
                  ),
                  // TabBar integrated into Header
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: Colors.black87,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Dine-in'),
                      Tab(text: 'Takeaway'),
                      Tab(text: 'Delivery'),
                      Tab(text: 'Drafts'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: _isFetching 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFFFC107)),
                SizedBox(height: 16),
                Text("Fetching your orders...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : HorizontalSwipeHitTestFilter(
            startPercentage: 0.15,
            endPercentage: 0.85,
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(), // Important for Android to allow boundary hit
              children: [
                _buildOrdersList(tableService, OrderStatus.all),
                _buildOrdersList(tableService, OrderStatus.dineIn),
                _buildOrdersList(tableService, OrderStatus.takeaway),
                _buildOrdersList(tableService, OrderStatus.delivery),
                _buildOrdersList(tableService, OrderStatus.drafts),
              ],
            ),
          ),
    );
  }

  Widget _buildOrdersList(TableService tableService, OrderStatus selectedStatus) {
    // Combine backend orders and local table drafts
    final allActiveItems = <Map<String, dynamic>>[];
    
    // Add backend orders (either all or active depending on if we want history)
    // For "All Orders", we show everything. For specific types, we show all of that type.
    for (var order in _backendOrders) {
      allActiveItems.add({
        'type': 'backend',
        'data': order,
        'order_type': order['order_type'] ?? 'Table',
        'table_id': order['table_id'],
        'status': order['status'],
      });
    }
    
    // Add local table drafts that DON'T have a backend order yet
    for (var tableId in tableService.activeTableIds) {
      final hasBackendOrder = _backendOrders.any((o) => o['table_id'] == tableId && o['status'] != 'Paid');
      if (!hasBackendOrder && tableService.getCart(tableId).isNotEmpty) {
        allActiveItems.add({
          'type': 'draft',
          'table_id': tableId,
          'order_type': 'Table', 
          'status': 'Draft',
        });
      }
    }

    final filteredItems = allActiveItems.where((item) {
      final orderType = item['order_type'] as String;
      final isDraft = item['type'] == 'draft';
      // final status = item['status'] as String; // Not directly used for filtering here, but for display

      if (selectedStatus == OrderStatus.all) return true;
      if (selectedStatus == OrderStatus.drafts) return isDraft;
      
      // For specific types, show all regardless of status (Paid or Pending)
      if (selectedStatus == OrderStatus.dineIn) return orderType == 'Table' && !isDraft;
      if (selectedStatus == OrderStatus.takeaway) return orderType == 'Takeaway';
      if (selectedStatus == OrderStatus.delivery) 
        return orderType.contains('Delivery');
      
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Orders List
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState(tableService, selectedStatus)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    
                    if (item['type'] == 'draft') {
                      final tableId = item['table_id'] as int;
                      return _buildModernOrderCard(
                        context,
                        tableId,
                        tableService.getTableName(tableId),
                        tableService.getCart(tableId),
                        tableService.getTableTotal(tableId),
                        false,
                        null,
                      );
                    } else {
                      final order = item['data'];
                      final tableId = order['table_id'] as int?;
                      return _buildModernOrderCard(
                        context,
                        tableId ?? 0,
                        tableId != null ? tableService.getTableName(tableId) : (order['order_type'] ?? 'Order'),
                        [], // Backend order items handled in card if needed, but display total
                        (order['total_amount'] as num?)?.toDouble() ?? 0.0,
                        true,
                        order,
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSaaSSummaryHeader(int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Management",
                  style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "$count tables require attention",
                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.black87, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOrderCard(
    BuildContext context,
    int tableId,
    String tableName,
    List<CartItem> cart,
    double total,
    bool isBooked,
    dynamic backendOrder,
  ) {
    final orderType = backendOrder?['order_type'] ?? 'Table';
    final status = backendOrder?['status'] ?? (isBooked ? "BOOKED" : "DRAFT");
    
    final statusColor = status == 'Paid' || status == 'Completed' 
        ? const Color(0xFF10B981)
        : status == 'Pending' || status == 'Draft' 
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    
    final statusLabel = status.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () async {
          if (tableId != 0) {
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => OrderOverviewScreen(
                tableId: tableId, 
                tableName: tableName,
                navigationItems: widget.navigationItems,
              ))
            );
            if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
            _fetchOrders();
          } else if (backendOrder != null) {
            if (backendOrder['table_id'] != null) {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => OrderOverviewScreen(
                  tableId: backendOrder['table_id'], 
                  tableName: "Table ${backendOrder['table_id']}",
                  navigationItems: widget.navigationItems,
                ))
              );
              if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
              _fetchOrders();
            } 
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      orderType == 'Table' ? Icons.table_restaurant_rounded : 
                      orderType == 'Takeaway' ? Icons.shopping_bag_rounded : Icons.delivery_dining_rounded, 
                      color: statusColor, 
                      size: 24
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tableId != 0 ? tableName : "Order #${backendOrder?['order_number']?.split('-').last ?? 'N/A'}", 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        Text(
                          backendOrder != null ? "Order #${backendOrder['order_number']}" : "Local Draft", 
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Amount", style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
                      Text("Rs ${NumberFormat('#,###').format(total)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (tableId != 0) {
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => OrderOverviewScreen(
                            tableId: tableId, 
                            tableName: tableName,
                            navigationItems: widget.navigationItems,
                          ))
                        );
                        if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
                        _fetchOrders();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF1E293B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text("View Details", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TableService tableService, OrderStatus selectedStatus) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            selectedStatus == OrderStatus.all 
              ? "No orders found in this branch" 
              : "No ${selectedStatus.name} orders",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          const Text(
            "Orders you place in POS will appear here.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Refresh Orders"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (tableService.isLoading) ...[
            const SizedBox(height: 16),
            const Text("Checking table drafts...", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

}
