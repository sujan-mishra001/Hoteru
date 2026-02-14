import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';

class InventoryProductsScreen extends StatefulWidget {
  const InventoryProductsScreen({super.key});

  @override
  State<InventoryProductsScreen> createState() => _InventoryProductsScreenState();
}

class _InventoryProductsScreenState extends State<InventoryProductsScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _inventory = [];
  List<dynamic> _lowStock = [];
  List<dynamic> _units = [];
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
    _units = await _inventoryService.getUnits();
    setState(() => _isLoading = false);
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
                'Products & Stock',
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
                        Icons.inventory_2_rounded,
                        size: 150,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
          ),
          if (_lowStock.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildLowStockWarning(),
            ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
                )
              : _inventory.isEmpty
                  ? _buildEmptyState()
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildInventoryCard(_inventory[index]),
                          childCount: _inventory.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFFFFC107),
        icon: const Icon(Icons.add_rounded, color: Colors.black87),
        label: const Text('Add Product', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => _loadData(),
      ),
    );
  }

  Widget _buildLowStockWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${_lowStock.length} items are running low!",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("View All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No products found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(dynamic item) {
    final quantity = (item['current_stock'] ?? 0.0).toDouble();
    final minQuantity = (item['min_stock'] ?? 0.0).toDouble();
    final isLow = quantity <= minQuantity;
    final unit = item['unit'] != null ? (item['unit']['abbreviation'] ?? '') : '';

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
                    "$quantity $unit",
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
    final unit = item['unit'] != null ? (item['unit']['abbreviation'] ?? '') : '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type == 'add' ? 'Add' : 'Remove'} Stock: ${item['name']}'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity ($unit)'),
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
    int? selectedUnitId;
    final qtyController = TextEditingController();
    final minQtyController = TextEditingController();
    final catController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedUnitId,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _units.map((u) => DropdownMenuItem<int>(
                    value: u['id'],
                    child: Text('${u['name']} (${u['abbreviation']})'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedUnitId = val),
                ),
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
                  await _inventoryService.createProduct({
                    'name': nameController.text,
                    'unit_id': selectedUnitId,
                    'current_stock': double.tryParse(qtyController.text),
                    'min_stock': double.tryParse(minQtyController.text),
                    'category': catController.text,
                  });
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
      ),
    );
  }

  void _showEditItemDialog(dynamic item) {
    final nameController = TextEditingController(text: item['name']);
    int? selectedUnitId = item['unit_id'];
    final minQtyController = TextEditingController(text: item['min_stock'].toString());
    final catController = TextEditingController(text: item['category']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedUnitId,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _units.map((u) => DropdownMenuItem<int>(
                    value: u['id'],
                    child: Text('${u['name']} (${u['abbreviation']})'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedUnitId = val),
                ),
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
                final success = await _inventoryService.updateProduct(item['id'], {
                  'name': nameController.text,
                  'unit_id': selectedUnitId,
                  'min_stock': double.tryParse(minQtyController.text),
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
