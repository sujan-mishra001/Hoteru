import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dautari_adda/features/pos/presentation/widgets/horizontal_swipe_hit_test_filter.dart';
import 'package:dautari_adda/features/pos/data/kot_service.dart';
import 'package:intl/intl.dart';

class KotManagementScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? navigationItems;
  const KotManagementScreen({super.key, this.navigationItems});

  @override
  State<KotManagementScreen> createState() => _KotManagementScreenState();
}

class _KotManagementScreenState extends State<KotManagementScreen> with SingleTickerProviderStateMixin {
  final KotService _kotService = KotService();
  late TabController _tabController;
  
  List<dynamic> _kots = [];
  bool _isLoading = true;
  String _selectedType = 'KOT'; // 'KOT' or 'BOT'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadKots();
  }

  Future<void> _loadKots() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    // Fetch all KOTs for the branch and we'll filter locally for a smoother UI experience
    final kots = await _kotService.getKots();
    if (!mounted) return;
    setState(() {
      _kots = kots;
      _isLoading = false;
    });
  }

  List<dynamic> _getFilteredKots(String status) {
    // First filter by type (KOT or BOT)
    final typeFiltered = _kots.where((kot) => 
      kot['kot_type']?.toString().toUpperCase() == _selectedType
    ).toList();

    // Then filter by status
    if (status == 'All') return typeFiltered;
    return typeFiltered.where((kot) => 
      kot['status']?.toString().toLowerCase() == status.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Text('KOT/BOT Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadKots,
          ),
        ],

      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[50], // Match scaffold background
            child: Column(
              children: [
                // KOT / BOT Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton('KOT', Icons.restaurant_menu_rounded),
                        ),
                        Expanded(
                          child: _buildTypeButton('BOT', Icons.local_bar_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.black87,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                    Tab(text: 'All'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : HorizontalSwipeHitTestFilter(
                    startPercentage: 0.15,
                    endPercentage: 0.85,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _buildKotList('Pending'),
                        _buildKotList('Completed'),
                        _buildKotList('All'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isSelected ? Colors.black87 : Colors.black54
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black87 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKotList(String status, {double internalPadding = 16.0}) {
    final filtered = _getFilteredKots(status);
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No $status orders found', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: internalPadding),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final kot = filtered[index];
        return _buildKotCard(kot);
      },
    );
  }

  Widget _buildKotCard(dynamic kot) {
    final items = kot['items'] as List? ?? [];
    final timestamp = DateTime.tryParse(kot['created_at'] ?? '') ?? DateTime.now();
    final isPending = kot['status'] == 'Pending';
    final table = kot['order']?['table']?['table_id'] ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${kot['kot_type'] ?? 'KOT'} #${kot['kot_number'] ?? kot['id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "${kot['kot_type']} • Table $table",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print_rounded, color: Colors.blue, size: 20),
                      onPressed: () => _printKot(kot['id']),
                      tooltip: "Print Ticket",
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPending ? Colors.orange : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        kot['status']?.toUpperCase() ?? 'N/A',
                        style: TextStyle(
                          color: isPending ? Colors.orange : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[100],
                  child: Text("${item['quantity']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                title: Text(item['menu_item']?['name'] ?? 'Unknown Item'),
                subtitle: item['notes'] != null && item['notes'].isNotEmpty 
                    ? Text(item['notes'], style: const TextStyle(color: Colors.red, fontSize: 10)) 
                    : null,
              );
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm • dd MMM').format(timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (isPending)
                  ElevatedButton(
                    onPressed: () => _completeKot(kot['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Mark Ready"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeKot(int id) async {
    final success = await _kotService.updateKotStatus(id, 'Completed');
    if (success) {
      _loadKots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order marked as completed"), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _printKot(int id) async {
    final success = await _kotService.printKot(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Print job sent to kitchen" : "Failed to send print job"),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }
}
