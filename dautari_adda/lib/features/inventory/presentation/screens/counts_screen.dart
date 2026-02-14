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
      appBar: AppBar(
        title: const Text('Physical Counts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _counts.isEmpty
              ? const Center(child: Text('No counts recorded yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _counts.length,
                  itemBuilder: (context, index) {
                    final txn = _counts[index];
                    final product = txn['product'] ?? {};
                    final unit = product['unit'] != null ? (product['unit']['abbreviation'] ?? '') : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(product['name'] ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(txn['notes'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text(
                              DateFormat('MMM d, HH:mm').format(DateTime.tryParse(txn['created_at']) ?? DateTime.now()),
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Diff: ${txn['quantity'] > 0 ? '+' : ''}${txn['quantity']} $unit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: txn['quantity'] >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCountDialog,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
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
