import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text(
          "Table Service",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_rounded, color: Colors.black54),
            onPressed: _showAddFloorDialog,
            tooltip: 'Manage Floors',
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
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.black54),
                    tooltip: 'Active Tables',
                    onPressed: () => _showNotifications(context, _tableService, activeIds),
                  ),
                  if (activeCount > 0)
                    Positioned(
                      right: 8,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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

          return RefreshIndicator(
            onRefresh: () => _tableService.fetchTables(),
            color: const Color(0xFFFFC107),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SaaS Quick Stats
              _buildSaaSQuickStats(),

              // Quick Category Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  "Menu Quick Access",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ),
              SizedBox(
                height: 48,
                child: _isLoadingMenu 
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFC107))))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _buildSaaSCategoryChip(cat.name, context);
                      },
                    ),
              ),

              // Floor Selection
              if (floors.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Floor Layout",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        "${tables.length} Tables",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                    ],
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
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedFloorId = floor.id);
                            _tableService.fetchTables(floorId: floor.id);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade200),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              floor.name,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Tables Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _tableService.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                    : tables.isEmpty
                      ? _buildEmptyTablesState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: tables.length,
                          itemBuilder: (context, index) {
                            final table = tables[index];
                            return _buildSaaSTableCard(table);
                          },
                        ),
                ),
              ),
            ],
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTableDialog,
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSaaSQuickStats() {
    final activeCount = _tableService.activeTableIds.length;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quick Snapshot",
                style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                activeCount == 0 ? "All Tables Available" : "$activeCount Tables Active",
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Reports",
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaaSCategoryChip(String label, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
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
          if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
        },
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSaaSTableCard(TableInfo table) {
    final isBooked = _tableService.isTableBooked(table.id);
    final hasItems = _tableService.getCart(table.id).isNotEmpty;
    
    Color statusColor = const Color(0xFF10B981); // Green
    String statusText = "OPEN";
    
    if (isBooked) {
      statusColor = const Color(0xFFEF4444); // Red
      statusText = "BOOKED";
    } else if (hasItems) {
      statusColor = const Color(0xFFF59E0B); // Orange
      statusText = "DRAFT";
    }

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
        if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_bar_rounded, size: 24, color: statusColor),
            ),
            const SizedBox(height: 12),
            Text(
              table.tableId,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTablesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "No Tables Configured",
            style: GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_selectedFloorId != null)
            ElevatedButton(
              onPressed: _showAddTableDialog,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
              child: const Text("Add First Table"),
            ),
        ],
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
