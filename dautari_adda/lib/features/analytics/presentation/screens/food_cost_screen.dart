import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/data/order_service.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';
import 'package:intl/intl.dart';

class FoodCostScreen extends StatefulWidget {
  const FoodCostScreen({super.key});

  @override
  State<FoodCostScreen> createState() => _FoodCostScreenState();
}

class _FoodCostScreenState extends State<FoodCostScreen> {
  final OrderService _orderService = OrderService();
  final InventoryService _inventoryService = InventoryService();
  
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  String _sortBy = 'name'; // name, cost, margin
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadFoodCost();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodCost() async {
    setState(() => _isLoading = true);
    try {
      final items = await _orderService.getAllMenuItems();
      
      // Calculate cost for each item based on ingredients
      final List<Map<String, dynamic>> itemsWithCost = [];
      
      for (var item in items) {
        final price = item['price']?.toDouble() ?? 0.0;
        // TODO: Calculate actual ingredient cost from BOM (Bill of Materials)
        // For now, we'll use a dummy calculation
        final estimatedCost = price * 0.3; // Assuming 30% food cost
        final margin = price - estimatedCost;
        final marginPercentage = price > 0 ? (margin / price) * 100 : 0;
        
        itemsWithCost.add({
          ...item,
          'estimated_cost': estimatedCost,
          'margin': margin,
          'margin_percentage': marginPercentage,
        });
      }
      
      setState(() {
        _menuItems = itemsWithCost;
        _filteredItems = _menuItems;
        _sortItems();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading food cost: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _menuItems.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final category = (item['category'] ?? '').toString().toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
      _sortItems();
    });
  }

  void _sortItems() {
    _filteredItems.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'cost':
          comparison = (a['estimated_cost'] ?? 0).compareTo(b['estimated_cost'] ?? 0);
          break;
        case 'margin':
          comparison = (a['margin_percentage'] ?? 0).compareTo(b['margin_percentage'] ?? 0);
          break;
        case 'price':
          comparison = (a['price'] ?? 0).compareTo(b['price'] ?? 0);
          break;
        default:
          comparison = (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeSortOrder(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortItems();
    });
  }

  Color _getMarginColor(double marginPercentage) {
    if (marginPercentage >= 70) return const Color(0xFF10b981);
    if (marginPercentage >= 50) return const Color(0xFF3b82f6);
    if (marginPercentage >= 30) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Cost Analysis'),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFoodCost,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Sort Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Sort by: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSortChip('Name', 'name'),
                    const SizedBox(width: 8),
                    _buildSortChip('Price', 'price'),
                    const SizedBox(width: 8),
                    _buildSortChip('Cost', 'cost'),
                    const SizedBox(width: 8),
                    _buildSortChip('Margin', 'margin'),
                  ],
                ),
              ],
            ),
          ),
          
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Items',
                    _filteredItems.length.toString(),
                    Icons.restaurant_menu,
                    const Color(0xFF3b82f6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Avg Margin',
                    '${_calculateAverageMargin().toStringAsFixed(1)}%',
                    Icons.trending_up,
                    const Color(0xFF10b981),
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No menu items found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildFoodCostCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String sortKey) {
    final isActive = _sortBy == sortKey;
    return InkWell(
      onTap: () => _changeSortOrder(sortKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFC107) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black87 : Colors.grey[700],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: Colors.black87,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageMargin() {
    if (_filteredItems.isEmpty) return 0.0;
    final totalMargin = _filteredItems.fold<double>(
      0.0,
      (sum, item) => sum + (item['margin_percentage']?.toDouble() ?? 0.0),
    );
    return totalMargin / _filteredItems.length;
  }

  Widget _buildFoodCostCard(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Unknown';
    final category = item['category'] ?? '';
    final price = item['price']?.toDouble() ?? 0.0;
    final cost = item['estimated_cost']?.toDouble() ?? 0.0;
    final margin = item['margin']?.toDouble() ?? 0.0;
    final marginPercentage = item['margin_percentage']?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMarginColor(marginPercentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${marginPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getMarginColor(marginPercentage),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCostItem(
                    'Selling Price',
                    price,
                    Icons.sell,
                    const Color(0xFF3b82f6),
                  ),
                ),
                Expanded(
                  child: _buildCostItem(
                    'Food Cost',
                    cost,
                    Icons.shopping_cart,
                    const Color(0xFFef4444),
                  ),
                ),
                Expanded(
                  child: _buildCostItem(
                    'Profit',
                    margin,
                    Icons.trending_up,
                    const Color(0xFF10b981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cost Breakdown Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: price > 0 ? cost / price : 0,
                backgroundColor: const Color(0xFF10b981).withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFef4444)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cost: ${price > 0 ? ((cost / price) * 100).toStringAsFixed(1) : '0'}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Margin: ${marginPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem(String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          NumberFormat('#,##0').format(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
