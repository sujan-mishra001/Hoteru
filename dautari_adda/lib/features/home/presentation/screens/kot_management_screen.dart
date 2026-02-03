import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/kot_service.dart';
import 'package:intl/intl.dart';

class KotManagementScreen extends StatefulWidget {
  const KotManagementScreen({super.key});

  @override
  State<KotManagementScreen> createState() => _KotManagementScreenState();
}

class _KotManagementScreenState extends State<KotManagementScreen> with SingleTickerProviderStateMixin {
  final KotService _kotService = KotService();
  late TabController _tabController;
  
  List<dynamic> _kots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadKots();
  }

  Future<void> _loadKots() async {
    setState(() => _isLoading = true);
    _kots = await _kotService.getKots();
    setState(() => _isLoading = false);
  }

  List<dynamic> _getFilteredKots(String status) {
    if (status == 'All') return _kots;
    return _kots.where((kot) => kot['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kitchen/Bar Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadKots,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black87,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildKotList('Pending'),
                _buildKotList('Completed'),
                _buildKotList('All'),
              ],
            ),
    );
  }

  Widget _buildKotList(String status) {
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
      padding: const EdgeInsets.all(16),
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
                      "KOT #${kot['kot_number'] ?? kot['id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "${kot['kot_type']} • Table $table",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
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
}
