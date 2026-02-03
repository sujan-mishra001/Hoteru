import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/home/data/table_service.dart';
import 'bill_screen.dart';

enum OrderStatus { all, pending, booked }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus _selectedStatus = OrderStatus.all;

  @override
  Widget build(BuildContext context) {
    final tableService = TableService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Manage Orders",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
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
          
          final filteredTableIds = activeTableIds.where((tableId) {
            if (_selectedStatus == OrderStatus.all) return true;
            final isBooked = tableService.isTableBooked(tableId);
            if (_selectedStatus == OrderStatus.booked) return isBooked;
            if (_selectedStatus == OrderStatus.pending) return !isBooked;
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SaaS Summary Stats
              _buildSaaSSummaryHeader(activeTableIds.length),

              // Filter Segment
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _buildSaaSTab("Active", OrderStatus.all, isSelected: _selectedStatus == OrderStatus.all),
                    const SizedBox(width: 12),
                    _buildSaaSTab("Drafts", OrderStatus.pending, isSelected: _selectedStatus == OrderStatus.pending),
                    const SizedBox(width: 12),
                    _buildSaaSTab("Booked", OrderStatus.booked, isSelected: _selectedStatus == OrderStatus.booked),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: filteredTableIds.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filteredTableIds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final tableId = filteredTableIds[index];
                          
                          // Check if it's an active backend order
                          final backendOrder = tableService.activeOrders.firstWhere(
                            (o) => o['table_id'] == tableId,
                            orElse: () => null,
                          );

                          final cart = tableService.getCart(tableId);
                          final tableName = tableService.getTableName(tableId);
                          final isBooked = tableService.isTableBooked(tableId);
                          
                          double total = tableService.getTableTotal(tableId);
                          if (backendOrder != null) {
                            total = (backendOrder['total_amount'] as num).toDouble();
                          }

                          return _buildModernOrderCard(
                            context,
                            tableId,
                            tableName,
                            cart,
                            total,
                            isBooked,
                            backendOrder,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaaSSummaryHeader(int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
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
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "$count tables require attention",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSaaSTab(String label, OrderStatus status, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC107) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFFC107) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.black87 : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
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
    final statusColor = isBooked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final statusLabel = isBooked ? "BOOKED" : "DRAFT";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => BillScreen(tableNumber: tableId)));
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
                    child: Icon(Icons.table_restaurant_rounded, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tableName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                        Text(backendOrder != null ? "Order #${backendOrder['order_number']}" : "Local Draft", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
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
                      Text("Total Amount", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      Text("Rs ${NumberFormat('#,###').format(total)}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BillScreen(tableNumber: tableId)));
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text("No active orders found", style: GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, OrderStatus status, int count) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    int tableId,
    String tableName,
    List<CartItem> cart,
    double total,
    bool isBooked,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillScreen(tableNumber: tableId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isBooked 
                          ? Colors.red.shade50 
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      color: isBooked ? Colors.red : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tableName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isBooked 
                                    ? Colors.red.shade100 
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isBooked ? "BOOKED" : "PENDING",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isBooked ? Colors.red.shade700 : Colors.orange.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.fastfood, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${cart.length} items",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),

              // Items List (max 3)
              ...cart.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${item.quantity}×",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.menuItem.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "Rs ${item.totalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),

              if (cart.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    "and ${cart.length - 3} more...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Rs ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillScreen(tableNumber: tableId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "View Bill",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
