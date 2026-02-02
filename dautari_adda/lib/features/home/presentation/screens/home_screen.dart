import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/presentation/screens/menu_screen.dart';
import 'package:dautari_adda/features/home/data/menu_service.dart';
import 'package:dautari_adda/features/home/data/menu_data.dart';
import 'package:dautari_adda/features/home/data/table_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSettingsTap;
  final Function(int)? onTabChange;
  final List<Map<String, dynamic>>? navigationItems;

  const HomeScreen({
    super.key, 
    this.onSettingsTap, 
    this.onTabChange, 
    this.navigationItems,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MenuService _menuService = MenuService();
  final TableService _tableService = TableService();
  List<MenuCategory> _categories = [];
  bool _isLoadingMenu = true;
  int? _selectedFloorId;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadFloors();
  }

  Future<void> _loadFloors() async {
    await _tableService.fetchFloors();
    if (_tableService.floors.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedFloorId = _tableService.floors.first.id;
        });
        _tableService.fetchTables(floorId: _selectedFloorId);
      }
    }
  }

  Future<void> _loadMenu() async {
    _menuService.getMenuStream().listen((data) {
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoadingMenu = false;
        });
      }
    });
  }

  void _showAddFloorDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Floor", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Name", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "e.g. Ground Floor, Roof Top",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await _tableService.createFloor(controller.text.trim());
                if (success) {
                  if (_selectedFloorId == null && _tableService.floors.isNotEmpty) {
                    setState(() => _selectedFloorId = _tableService.floors.last.id);
                    _tableService.fetchTables(floorId: _selectedFloorId);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Floor added successfully"), backgroundColor: Colors.green),
                    );
                  }
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            child: const Text("Add Floor"),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog() {
    if (_selectedFloorId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add or select a floor first")),
      );
      return;
    }
    
    final idController = TextEditingController();
    final capacityController = TextEditingController(text: "4");
    String selectedType = "Regular";
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add New Table", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Table ID / Name", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    hintText: "e.g. T1, VIP-2",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text("Capacity", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Number of seats",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Table Type", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      items: ["Regular", "VIP", "Outdoor", "Private"]
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.isNotEmpty) {
                  final cap = int.tryParse(capacityController.text) ?? 4;
                  final success = await _tableService.createTable(
                    idController.text.trim(), 
                    _selectedFloorId!,
                    capacity: cap,
                    type: selectedType,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Table added successfully"), backgroundColor: Colors.green),
                    );
                  }
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              child: const Text("Add Table"),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, TableService tableService, List<int> activeIds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFFFC107)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pending Orders",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Active tables requiring attention",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: activeIds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text("All clear!", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const Text("No pending orders at the moment", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: activeIds.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tableId = activeIds[index];
                        final isBooked = tableService.isTableBooked(tableId);
                        final itemsCount = tableService.getCart(tableId).length;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isBooked ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.table_restaurant,
                                color: isBooked ? Colors.red : Colors.orange,
                              ),
                            ),
                            title: Text(
                              tableService.getTableName(tableId),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text("$itemsCount items ordered", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBooked ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isBooked ? "BOOKED" : "PENDING",
                                    style: TextStyle(
                                      color: isBooked ? Colors.red : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuScreen(tableNumber: tableId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Dautari Adda",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_rounded, color: Colors.black87),
            onPressed: _showAddFloorDialog,
            tooltip: 'Add Floor',
          ),
          ListenableBuilder(
            listenable: _tableService,
            builder: (context, _) {
              final activeIds = _tableService.activeTableIds;
              final activeCount = activeIds.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
                    tooltip: 'Pending Orders',
                    onPressed: () => _showNotifications(context, _tableService, activeIds),
                  ),
                  if (activeCount > 0)
                    Positioned(
                      right: 8,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _tableService,
        builder: (context, child) {
          final floors = _tableService.floors;
          final tables = _tableService.tables;
          final allBills = _tableService.pastBills;
          
          final now = DateTime.now();
          final todayBills = allBills.where((bill) {
            return bill.date.year == now.year &&
                   bill.date.month == now.month &&
                   bill.date.day == now.day;
          }).toList();
          final todayRevenue = todayBills.fold(0.0, (sum, bill) => sum + bill.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22FFC107),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      _buildEnhancedStatCard(
                        icon: Icons.receipt_long_rounded,
                        label: "Active Orders",
                        value: "${_tableService.activeTableIds.length}",
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      _buildEnhancedStatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Today's Revenue",
                        value: "Rs ${todayRevenue.toStringAsFixed(0)}",
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),

              // Food Categories Quick Links
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  "Food Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              SizedBox(
                height: 50,
                child: _isLoadingMenu 
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFC107))))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _buildQuickCategory(
                          _getIconForCategory(cat.name), 
                          cat.name, 
                          _getColorForCategory(cat.name), 
                          context
                        );
                      },
                    ),
              ),
              if (floors.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    "Select Floor",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: floors.length,
                    itemBuilder: (context, index) {
                      final floor = floors[index];
                      final isSelected = _selectedFloorId == floor.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(floor.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFloorId = floor.id);
                              _tableService.fetchTables(floorId: floor.id);
                            }
                          },
                          selectedColor: const Color(0xFFFFC107),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Tables Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      floors.any((f) => f.id == _selectedFloorId) 
                        ? "${floors.firstWhere((f) => f.id == _selectedFloorId).name} Tables"
                        : "Tables",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFFFFC107)),
                      onPressed: _showAddTableDialog,
                      tooltip: 'Add Table',
                    ),
                  ],
                ),
              ),

              // Tables Grid
              Expanded(
                child: _tableService.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                  : tables.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_restaurant_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text("No tables found", style: TextStyle(color: Colors.grey)),
                            if (_selectedFloorId != null)
                              TextButton(
                                onPressed: _showAddTableDialog,
                                child: const Text("Add First Table"),
                              ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: tables.length,
                        itemBuilder: (context, index) {
                          final table = tables[index];
                          final isBooked = _tableService.isTableBooked(table.id);
                          final hasItems = _tableService.getCart(table.id).isNotEmpty;
                          
                          return InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuScreen(
                                    tableNumber: table.id,
                                    navigationItems: widget.navigationItems,
                                  ),
                                ),
                              );
                              if (result is int && widget.onTabChange != null) {
                                widget.onTabChange!(result);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isBooked 
                                      ? Colors.red.withOpacity(0.5) 
                                      : hasItems 
                                          ? Colors.orange.withOpacity(0.5) 
                                          : Colors.grey.withOpacity(0.1),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (isBooked ? Colors.red : hasItems ? Colors.orange : const Color(0xFFFFC107)).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.table_bar_rounded,
                                      size: 24,
                                      color: isBooked ? Colors.red : hasItems ? Colors.orange : const Color(0xFFFFC107),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    table.tableId,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isBooked ? "BOOKED" : hasItems ? "PENDING" : "OPEN",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isBooked ? Colors.red : hasItems ? Colors.orange : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
      ),
    );
  }


  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCategory(IconData icon, String label, Color color, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: ActionChip(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                tableNumber: 1, 
                initialSearch: label,
                navigationItems: widget.navigationItems,
              ),
            ),
          );
          if (result is int && widget.onTabChange != null) {
            widget.onTabChange!(result);
          }
        },
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: BorderSide(color: color.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    name = name.toLowerCase();
    if (name.contains('bev') || name.contains('coffee') || name.contains('tea')) return Icons.coffee_rounded;
    if (name.contains('food') || name.contains('snack')) return Icons.restaurant_rounded;
    if (name.contains('dairy')) return Icons.icecream_rounded;
    if (name.contains('dal')) return Icons.soup_kitchen_rounded;
    if (name.contains('drink') || name.contains('beer') || name.contains('whisky')) return Icons.local_bar_rounded;
    if (name.contains('smoke')) return Icons.smoking_rooms_rounded;
    return Icons.restaurant_menu_rounded;
  }

  Color _getColorForCategory(String name) {
    name = name.toLowerCase();
    if (name.contains('bev')) return Colors.brown;
    if (name.contains('food')) return Colors.pink;
    if (name.contains('dairy')) return Colors.blue;
    if (name.contains('dal')) return Colors.green;
    if (name.contains('drink')) return Colors.purple;
    if (name.contains('smoke')) return Colors.blueGrey;
    return Colors.orange;
  }
}
