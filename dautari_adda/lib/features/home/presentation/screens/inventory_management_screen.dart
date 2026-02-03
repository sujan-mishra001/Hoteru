import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/inventory_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _inventory = [];
  List<dynamic> _lowStock = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _inventory = await _inventoryService.getInventory(search: _searchController.text);
    _lowStock = await _inventoryService.getLowStockItems();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => _loadData(),
            ),
          ),
          if (_lowStock.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "${_lowStock.length} items are running low on stock!",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Filter by low stock
                    },
                    child: const Text("View All", style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : _inventory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No inventory items found', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _inventory.length,
                        itemBuilder: (context, index) {
                          final item = _inventory[index];
                          return _buildInventoryCard(item);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add_rounded, color: Colors.black87),
      ),
    );
  }

  Widget _buildInventoryCard(dynamic item) {
    final quantity = (item['quantity'] ?? 0.0) as double;
    final minQuantity = (item['min_quantity'] ?? 0.0) as double;
    final isLow = quantity <= minQuantity;
    
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isLow ? Colors.red : Colors.green).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_rounded, 
            color: isLow ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          item['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Category: ${item['category'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isLow ? Colors.red : Colors.green).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$quantity ${item['unit'] ?? ''}",
                    style: TextStyle(
                      color: isLow ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Min: $minQuantity', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(value, item),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'stock_add', child: Text('Add Stock')),
            const PopupMenuItem(value: 'stock_remove', child: Text('Remove Stock')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ),
    );
  }

  void _handleAction(String action, dynamic item) {
    if (action == 'edit') {
      _showEditItemDialog(item);
    } else if (action == 'delete') {
      _confirmDelete(item);
    } else if (action.startsWith('stock_')) {
      _showUpdateStockDialog(item, action.split('_')[1]);
    }
  }

  void _showUpdateStockDialog(dynamic item, String type) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type == 'add' ? 'Add' : 'Remove'} Stock: ${item['name']}'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity (${item['unit']})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text);
              if (qty != null) {
                final success = await _inventoryService.updateStock(item['id'], qty, type);
                if (success) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final qtyController = TextEditingController();
    final minQtyController = TextEditingController();
    final catController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
              const SizedBox(height: 12),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (e.g. kg, pcs, l)')),
              const SizedBox(height: 12),
              TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Initial Quantity'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: minQtyController, decoration: const InputDecoration(labelText: 'Min Quantity'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: catController, decoration: const InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _inventoryService.createInventoryItem(
                  name: nameController.text,
                  unit: unitController.text,
                  quantity: double.tryParse(qtyController.text),
                  minQuantity: double.tryParse(minQtyController.text),
                  category: catController.text,
                );
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                _showError(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(dynamic item) {
    final nameController = TextEditingController(text: item['name']);
    final unitController = TextEditingController(text: item['unit']);
    final minQtyController = TextEditingController(text: item['min_quantity'].toString());
    final catController = TextEditingController(text: item['category']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
              const SizedBox(height: 12),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
              const SizedBox(height: 12),
              TextField(controller: minQtyController, decoration: const InputDecoration(labelText: 'Min Quantity'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: catController, decoration: const InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _inventoryService.updateInventoryItem(item['id'], {
                'name': nameController.text,
                'unit': unitController.text,
                'min_quantity': double.tryParse(minQtyController.text),
                'category': catController.text,
              });
              if (success) {
                Navigator.pop(context);
                _loadData();
              } else {
                _showError('Failed to update');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await _inventoryService.deleteInventoryItem(item['id']);
              if (success) {
                Navigator.pop(context);
                _loadData();
              } else {
                _showError('Failed to delete');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
}
