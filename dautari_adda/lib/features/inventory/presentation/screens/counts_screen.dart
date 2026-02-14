import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';
import 'package:intl/intl.dart';

class CountsScreen extends StatefulWidget {
  const CountsScreen({super.key});

  @override
  State<CountsScreen> createState() => _CountsScreenState();
}

class _CountsScreenState extends State<CountsScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _counts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final counts = await _inventoryService.getCounts();
    setState(() {
      _counts = counts;
      _isLoading = false;
    });
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
                'Physical Counts',
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
                        Icons.fact_check_rounded,
                        size: 150,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.black87), onPressed: _loadData),
            ],
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
                )
              : _counts.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text('No counts recorded yet')),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final txn = _counts[index];
                            final product = txn['product'] ?? {};
                            final unit = product['unit'] != null ? (product['unit']['abbreviation'] ?? '') : '';

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
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.assignment_rounded, color: Color(0xFFFFC107), size: 20),
                                ),
                                title: Text(product['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(txn['notes'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text(
                                      DateFormat('MMM d, HH:mm').format(DateTime.tryParse(txn['created_at']) ?? DateTime.now()),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  'Diff: ${txn['quantity'] >= 0 ? '+' : ''}${txn['quantity']} $unit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: txn['quantity'] >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _counts.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCountDialog,
        backgroundColor: const Color(0xFFFFC107),
        icon: const Icon(Icons.add_rounded, color: Colors.black87),
        label: const Text('Add Audit', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddCountDialog() async {
    final products = await _inventoryService.getProducts();
    if (!mounted) return;

    int? selectedProductId;
    final countController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Physical Count'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Product'),
                  items: products.map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                    value: p['id'],
                    child: Text(p['name']),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedProductId = val),
                ),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Counted Quantity'),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedProductId != null && countController.text.isNotEmpty) {
                  final success = await _inventoryService.createCount({
                    'product_id': selectedProductId,
                    'counted_quantity': double.tryParse(countController.text),
                    'notes': notesController.text,
                  });
                  if (success) {
                    Navigator.pop(context);
                    _loadData();
                  }
                }
              },
              child: const Text('Save Count'),
            ),
          ],
        ),
      ),
    );
  }
}
