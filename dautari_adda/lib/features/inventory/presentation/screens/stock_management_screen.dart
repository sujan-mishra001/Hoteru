import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';
import 'package:intl/intl.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final txns = await _inventoryService.getTransactions();
    setState(() {
      _transactions = txns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Stock Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final txn = _transactions[index];
                    final product = txn['product'] ?? {};
                    final unit = product['unit'] != null ? (product['unit']['abbreviation'] ?? '') : '';
                    final isPositive = ['IN', 'Add', 'Production_IN'].contains(txn['transaction_type']) ||
                                       (['Adjustment', 'Count'].contains(txn['transaction_type']) && (txn['quantity'] ?? 0) > 0);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(product['name'] ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${txn['transaction_type']} | ${txn['notes'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text(
                              DateFormat('MMM d, HH:mm').format(DateTime.tryParse(txn['created_at']) ?? DateTime.now()),
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${isPositive ? '+' : ''}${txn['quantity']} $unit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showAddTransactionDialog() async {
    final products = await _inventoryService.getProducts();
    if (!mounted) return;

    int? selectedProductId;
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Stock (Transaction)'),
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
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes/Reference'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedProductId != null && qtyController.text.isNotEmpty) {
                  final success = await _inventoryService.createTransaction({
                    'product_id': selectedProductId,
                    'quantity': double.tryParse(qtyController.text),
                    'notes': notesController.text,
                  });
                  if (success) {
                    Navigator.pop(context);
                    _loadData();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
