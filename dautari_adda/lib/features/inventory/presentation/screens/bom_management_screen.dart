import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';
import 'add_bom_screen.dart';

class BOMManagementScreen extends StatefulWidget {
  const BOMManagementScreen({super.key});

  @override
  State<BOMManagementScreen> createState() => _BOMManagementScreenState();
}

class _BOMManagementScreenState extends State<BOMManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _boms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final boms = await _inventoryService.getBoms();
    setState(() {
      _boms = boms;
      _isLoading = false;
    });
  }

  void _navigateToAddEdit(dynamic bom) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBOMScreen(initialBOM: bom)),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: const Color(0xFFFFC107),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Recipes (BOM)',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 150,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
                )
              : _boms.isEmpty
                  ? _buildEmptyState()
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildBOMCard(_boms[index]),
                          childCount: _boms.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(null),
        backgroundColor: const Color(0xFFFFC107),
        icon: const Icon(Icons.add_rounded, color: Colors.black87),
        label: const Text('New Recipe', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No BOMs found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBOMCard(dynamic bom) {
    final components = bom['components'] as List<dynamic>? ?? [];
    
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
        title: Text(bom['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Produces ${bom['output_quantity']} units • ${components.length} components', style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _navigateToAddEdit(bom),
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Column(
              children: components.map<Widget>((comp) {
                final product = comp['product'] ?? {};
                final unit = comp['unit'] != null ? (comp['unit']['abbreviation'] ?? '') : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product['name'] ?? 'Unknown Item', style: const TextStyle(fontSize: 13)),
                      Text('${comp['quantity']} $unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
