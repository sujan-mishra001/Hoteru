import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/data/order_service.dart';
import 'package:dautari_adda/features/pos/presentation/widgets/horizontal_swipe_hit_test_filter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'order_overview_screen.dart';
import 'takeaway_order_screen.dart';
import 'delivery_order_screen.dart';

enum OrderStatus { dineIn, takeaway, delivery, drafts }

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
    _tabController = TabController(length: 4, vsync: this);
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
      final orders = await _orderService.getOrders();
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
        toolbarHeight: 75,
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

      ),
      body: ListenableBuilder(
        listenable: tableService,
        builder: (context, _) {
          final activeTableIds = tableService.activeTableIds;
          // Only count orders that require attention (not completed/paid/cancelled)
          final activeStatuses = ['pending', 'preparing', 'ready', 'draft', 'booked'];
          final pendingTakeaway = _backendOrders.where((o) {
            final orderType = (o['order_type'] ?? '').toString().toLowerCase();
            final status = (o['status'] ?? '').toString().toLowerCase();
            return orderType == 'takeaway' && activeStatuses.contains(status);
          }).length;
          final pendingDelivery = _backendOrders.where((o) {
            final orderType = (o['order_type'] ?? '').toString().toLowerCase();
            final status = (o['status'] ?? '').toString().toLowerCase();
            return orderType.contains('delivery') && activeStatuses.contains(status);
          }).length;
          final totalAttention = activeTableIds.length + pendingTakeaway + pendingDelivery;
          return Column(
            children: [
              Container(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                                  "$totalActiveKOTs active KOTs require attention",
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
                    TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      tabAlignment: TabAlignment.fill,
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Colors.black87,
                      indicatorWeight: 3,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                      tabs: const [
                        Tab(text: 'Dine-in'),
                        Tab(text: 'Takeaway'),
                        Tab(text: 'Delivery'),
                        Tab(text: 'Drafts'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isFetching 
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
                          _buildOrdersList(tableService, OrderStatus.dineIn),
                          _buildOrdersList(tableService, OrderStatus.takeaway),
                          _buildOrdersList(tableService, OrderStatus.delivery),
                          _buildOrdersList(tableService, OrderStatus.drafts),
                        ],
                      ),
                    ),
              ),
            ],
          );
        },
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
      final orderType = (item['order_type'] as String? ?? '').toString();
      final orderTypeLower = orderType.toLowerCase();
      final isDraft = item['type'] == 'draft';

      if (selectedStatus == OrderStatus.drafts) return isDraft;
      
      // Strict type matching - ensure complete isolation between order types
      if (selectedStatus == OrderStatus.dineIn) return (orderTypeLower == 'table' || orderTypeLower == 'dine-in') && !isDraft;
      if (selectedStatus == OrderStatus.takeaway) return orderTypeLower == 'takeaway' && !orderTypeLower.contains('delivery');
      if (selectedStatus == OrderStatus.delivery) return orderTypeLower == 'delivery' || orderTypeLower == 'delivery partner';
      
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
                      String displayName;
                      final orderType = (order['order_type'] ?? '').toString().toLowerCase();
                      if (tableId != null && tableId > 0) {
                        displayName = tableService.getTableName(tableId);
                      } else if (orderType == 'takeaway') {
                        final customerName = order['customer']?['name']?.toString();
                        displayName = customerName != null && customerName.isNotEmpty ? 'Takeaway • $customerName' : 'Takeaway';
                      } else if (orderType.contains('delivery')) {
                        final deliveryPartner = order['delivery_partner'];
                        final partnerName = deliveryPartner?['name']?.toString() ?? 'Self Delivery';
                        final customerName = order['customer']?['name']?.toString();
                        if (customerName != null && customerName.isNotEmpty) {
                          displayName = 'Delivery ($partnerName) • $customerName';
                        } else {
                          displayName = 'Delivery ($partnerName)';
                        }
                      } else {
                        displayName = order['order_type'] ?? 'Order';
                      }
                      return _buildModernOrderCard(
                        context,
                        tableId ?? 0,
                        displayName,
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
            // Dine-in order - use OrderOverviewScreen with table
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
            final orderType = (backendOrder['order_type'] ?? '').toString().toLowerCase();
            final customerName = backendOrder['customer']?['name']?.toString() ?? '';
            final orderId = backendOrder['id'];
            final deliveryPartnerId = backendOrder['delivery_partner_id'];
            final deliveryPartner = backendOrder['delivery_partner'];
            final partnerName = deliveryPartner?['name']?.toString();
            
            if (orderType == 'takeaway') {
              // Takeaway order - use TakeawayOrderScreen
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => TakeawayOrderScreen(
                  orderId: orderId,
                  customerName: customerName,
                  navigationItems: widget.navigationItems,
                ))
              );
              if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
              _fetchOrders();
            } else if (orderType == 'delivery' || orderType.contains('delivery')) {
              // Delivery order - use DeliveryOrderScreen
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => DeliveryOrderScreen(
                  orderId: orderId,
                  customerName: customerName,
                  deliveryPartnerName: partnerName,
                  deliveryPartnerId: deliveryPartnerId,
                  navigationItems: widget.navigationItems,
                ))
              );
              if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
              _fetchOrders();
            } else {
              // Fallback to OrderOverviewScreen for other types
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => OrderOverviewScreen(
                  tableId: backendOrder['table_id'] ?? 0, 
                  tableName: tableName,
                  navigationItems: widget.navigationItems,
                  orderType: backendOrder['order_type'],
                  customerName: customerName,
                  deliveryPartnerId: deliveryPartnerId,
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
                          tableName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        if (backendOrder != null && backendOrder['customer'] != null)
                          Text(
                            "Customer: ${backendOrder['customer']['name']}",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (backendOrder != null && backendOrder['delivery_partner'] != null)
                          Text(
                            "Partner: ${backendOrder['delivery_partner']['name']}",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
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
                      if (backendOrder != null && backendOrder['id'] != null) {
                        // Confirmed order: Show Bill Dialog
                         _showBillDialog(context, backendOrder['id']);
                      } else if (tableId != 0) {
                        // Draft: Navigate to Overview
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

  Future<void> _showBillDialog(BuildContext context, int orderId) async {
    // 1. Fetch full details if needed (or just ensure we have latest)
    // We show a dialog with FutureBuilder or similar, or just fetch then show.
    // Let's show a loading dialog first or just render the dialog with a FutureBuilder.
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _orderService.getOrder(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text("Failed to load bill details"),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                  ],
                ),
              );
            }

            final order = snapshot.data!;
            final items = order['items'] as List? ?? [];
            final subtotal = (order['gross_amount'] as num?)?.toDouble() ?? 0.0;
            final discount = (order['discount'] as num?)?.toDouble() ?? 0.0;
            final serviceCharge = (order['service_charge'] as num?)?.toDouble() ?? 0.0;
            final tax = (order['tax'] as num?)?.toDouble() ?? 0.0;
            final total = (order['net_amount'] as num?)?.toDouble() ?? 0.0;
            final orderNumber = order['order_number'] ?? order['id'].toString();
            final date = order['created_at'] != null 
                ? DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(order['created_at']))
                : '-';

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bill #$orderNumber", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text("Dautari Adda", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(date, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Divider(height: 32),
                          if (items.isEmpty)
                            const Center(child: Text("No items found"))
                          else
                            ...items.map((item) {
                              final name = item['menu_item']?['name'] ?? 'Item';
                              final qty = item['quantity'] ?? 0;
                              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                              final total = (item['subtotal'] as num?)?.toDouble() ?? (price * qty);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text("$qty x $name", style: GoogleFonts.poppins(fontSize: 13))),
                                    Text("Rs ${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            }),
                          const Divider(height: 32),
                          _buildBillSummaryRow("Subtotal", subtotal),
                          if (discount > 0) _buildBillSummaryRow("Discount", -discount, isDiscount: true),
                          if (serviceCharge > 0) _buildBillSummaryRow("Service Charge", serviceCharge),
                          if (tax > 0) _buildBillSummaryRow("Tax", tax),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Grand Total", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text("Rs ${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFC107))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: order['status'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order['status']?.toUpperCase() ?? 'UNKNOWN',
                                style: GoogleFonts.poppins(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: order['status'] == 'Paid' ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () { 
                             // TODO: Implement actual printing logic
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Printing Bill..."))
                             );
                             // If there is an API:
                             // _orderService.printBill(orderId);
                          },
                          icon: const Icon(Icons.print),
                          label: const Text("Print Bill"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.black12),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          Text(
            "Rs ${amount.toStringAsFixed(0)}", 
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, 
              color: isDiscount ? Colors.green : Colors.black87
            )
          ),
        ],
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
            "No ${selectedStatus.name} orders",
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
