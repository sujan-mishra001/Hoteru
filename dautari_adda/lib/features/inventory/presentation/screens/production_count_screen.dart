import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';
import 'package:intl/intl.dart';

class ProductionCountScreen extends StatefulWidget {
  const ProductionCountScreen({super.key});

  @override
  State<ProductionCountScreen> createState() => _ProductionCountScreenState();
}

class _ProductionCountScreenState extends State<ProductionCountScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _productions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final productions = await _inventoryService.getProductions();
    setState(() {
      _productions = productions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Production History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _productions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _productions.length,
                  itemBuilder: (context, index) {
                    final prod = _productions[index];
                    return _buildProductionCard(prod);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No production history found.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionCard(dynamic prod) {
    final bomName = prod['bom']?['name'] ?? 'Unknown BOM';
    final prodNum = prod['production_number'] ?? 'N/A';
    final date = DateTime.tryParse(prod['created_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy • HH:mm').format(date);
    final totalProduced = prod['total_produced'] ?? 0.0;
    final remaining = prod['remaining_quantity'] ?? 0.0;
    final consumed = prod['consumed_quantity'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
        ),
        title: Text(
          bomName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Batch: $prodNum • $formattedDate', style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Qty: $totalProduced',
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Produced Quantity', totalProduced.toString()),
                _buildInfoRow('Consumed (Sales)', consumed.toString(), color: Colors.orange),
                _buildInfoRow('Remaining Stock', remaining.toString(), color: Colors.green, isBold: true),
                const Divider(),
                if (prod['notes'] != null && prod['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prod['notes'],
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
