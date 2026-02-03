import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/home/data/reports_service.dart';
import 'package:dautari_adda/features/home/data/session_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ReportsService _reportsService = ReportsService();
  final SessionService _sessionService = SessionService();
  
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _activeSession;
  bool _isLoading = true;
  String _sessionDuration = '00:00:00';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _reportsService.getDashboardSummary();
      final sessions = await _sessionService.getSessions(limit: 10);
      
      final activeSessions = (sessions).where((s) => s['status'] == 'Open').toList();
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _activeSession = activeSessions.isNotEmpty ? activeSessions.first : null;
          _isLoading = false;
        });
        if (_activeSession != null) _startSessionTimer();
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startSessionTimer() {
    if (_activeSession == null) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _activeSession != null) {
        final startTimeStr = _activeSession!['start_time'];
        final startTime = DateTime.parse(startTimeStr);
        final now = DateTime.now();
        final diff = now.difference(startTime);
        
        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        
        setState(() {
          _sessionDuration = '$hours:$minutes:$seconds';
        });
        
        _startSessionTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Business Overview',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFFFFC107),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Stats Row
                    _buildModernHeaderStats(),
                    const SizedBox(height: 24),
                    
                    // Session Card (if active)
                    if (_activeSession != null) ...[
                      _buildModernSessionCard(),
                      const SizedBox(height: 24),
                    ],

                    // Performance Charts/Summary
                    Text(
                      'Financial Metrics',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModernSalesGrid(),
                    const SizedBox(height: 24),
                    
                    // Top Sellers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top Performing Items',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('View All', style: GoogleFonts.poppins(color: const Color(0xFFFFC107), fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                    _buildModernTopSellers(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModernHeaderStats() {
    final orders24h = _dashboardData?['orders_24h'] ?? 0;
    final sales24h = _dashboardData?['sales_24h']?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildHeaderStatItem(
            'Today\'s Orders',
            orders24h.toString(),
            Icons.shopping_bag_rounded,
            const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHeaderStatItem(
            'Today\'s Revenue',
            'Rs ${NumberFormat('#,###').format(sales24h)}',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSessionCard() {
    final user = _activeSession?['user'];
    final fullName = user != null ? user['full_name'] : 'System User';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active Session',
                          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _sessionDuration,
                  style: GoogleFonts.jetbrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSessionMiniStat('Sales', 'Rs ${_activeSession?['total_sales'] ?? 0}'),
              _buildSessionMiniStat('Orders', '${_activeSession?['total_orders'] ?? 0}'),
              _buildSessionMiniStat('Cash', 'Rs ${_activeSession?['opening_cash'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildModernSalesGrid() {
    final paidSales = _dashboardData?['paid_sales']?.toDouble() ?? 0.0;
    final creditSales = _dashboardData?['credit_sales']?.toDouble() ?? 0.0;
    final occupancy = _dashboardData?['occupancy']?.toDouble() ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildGridStatItem('Paid Revenue', 'Rs ${NumberFormat('#,###').format(paidSales)}', Icons.check_circle_outline_rounded, Colors.green),
        _buildGridStatItem('Credit Owed', 'Rs ${NumberFormat('#,###').format(creditSales)}', Icons.timer_outlined, Colors.orange),
        _buildGridStatItem('Occupancy', '${occupancy.toStringAsFixed(1)}%', Icons.table_bar_rounded, Colors.blue),
        _buildGridStatItem('Dine-In Orders', '${_dashboardData?['dine_in_count'] ?? 0}', Icons.restaurant_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildGridStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTopSellers() {
    final topItems = _dashboardData?['top_selling_items'] as List? ?? [];
    if (topItems.isEmpty) return _buildEmptyState('No top items recorded');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topItems.length > 4 ? 4 : topItems.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade50),
        itemBuilder: (context, index) {
          final item = topItems[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text('#${index + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
              ),
            ),
            title: Text(item['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${item['quantity']} units sold', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            trailing: Text(
              'Rs ${item['revenue']}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[200]),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }
}

  Widget _buildSessionCard() {
    final userName = _activeSession?['user']?['full_name'] ?? 'Unknown User';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10b981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.access_time, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Session',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sessionDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  Widget _buildSalesSummaryCards() {
    final sales24h = _dashboardData?['sales_24h']?.toDouble() ?? 0.0;
    final paidSales = _dashboardData?['paid_sales']?.toDouble() ?? 0.0;
    final creditSales = _dashboardData?['credit_sales']?.toDouble() ?? 0.0;
    final discount = _dashboardData?['discount']?.toDouble() ?? 0.0;
    final occupancy = _dashboardData?['occupancy']?.toDouble() ?? 0.0;
    final totalTables = _dashboardData?['total_tables'] ?? 0;
    final occupiedTables = _dashboardData?['occupied_tables'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Summary (24h)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sales',
                'NPR ${NumberFormat('#,##0.00').format(sales24h)}',
                Icons.trending_up,
                const Color(0xFF3b82f6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Paid Sales',
                'NPR ${NumberFormat('#,##0.00').format(paidSales)}',
                Icons.check_circle,
                const Color(0xFF10b981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Credit Sales',
                'NPR ${NumberFormat('#,##0.00').format(creditSales)}',
                Icons.credit_card,
                const Color(0xFFf59e0b),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Discount',
                'NPR ${NumberFormat('#,##0.00').format(discount)}',
                Icons.local_offer,
                const Color(0xFFef4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Table Occupancy',
                '${occupancy.toStringAsFixed(1)}%',
                Icons.table_restaurant,
                const Color(0xFF8b5cf6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tables',
                '$occupiedTables / $totalTables',
                Icons.event_seat,
                const Color(0xFF06b6d4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatistics() {
    final orders24h = _dashboardData?['orders_24h'] ?? 0;
    final dineInCount = _dashboardData?['dine_in_count'] ?? 0;
    final takeawayCount = _dashboardData?['takeaway_count'] ?? 0;
    final deliveryCount = _dashboardData?['delivery_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Statistics (24h)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOrderRow('Total Orders', orders24h.toString(), Icons.shopping_bag, const Color(0xFF3b82f6)),
                const Divider(height: 24),
                _buildOrderRow('Dine In', dineInCount.toString(), Icons.restaurant, const Color(0xFF10b981)),
                const SizedBox(height: 12),
                _buildOrderRow('Takeaway', takeawayCount.toString(), Icons.shopping_basket, const Color(0xFFf59e0b)),
                const SizedBox(height: 12),
                _buildOrderRow('Delivery', deliveryCount.toString(), Icons.delivery_dining, const Color(0xFFef4444)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(String label, String count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSellingItems() {
    final topItems = _dashboardData?['top_selling_items'] as List? ?? [];
    
    if (topItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Selling Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topItems.length > 5 ? 5 : topItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = topItems[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFC107).withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Qty: ${item['quantity'] ?? 0}'),
                trailing: Text(
                  'NPR ${NumberFormat('#,##0.00').format(item['revenue']?.toDouble() ?? 0.0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10b981),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSalesByArea() {
    final salesByArea = _dashboardData?['sales_by_area'] as List? ?? [];
    
    if (salesByArea.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales by Area',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: salesByArea.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final area = salesByArea[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFFFFC107)),
                title: Text(
                  area['area'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  'NPR ${NumberFormat('#,##0.00').format(area['amount']?.toDouble() ?? 0.0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
