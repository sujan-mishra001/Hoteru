import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/presentation/screens/order_overview_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_screen.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';
import 'package:dautari_adda/core/services/sync_service.dart';
import 'package:provider/provider.dart';

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
  final TableService _tableService = TableService();
  final SyncService _syncService = SyncService();
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
    if (!_syncService.isCacheValid) {
      await _syncService.syncPOSData();
    }
    if (mounted) {
      setState(() {
        _categories = _syncService.categories;
        _isLoadingMenu = false;
      });
    }
    
    // Listen for updates
    _syncService.addListener(_onSyncUpdate);
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {
        _categories = _syncService.categories;
      });
    }
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    super.dispose();
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
                                  builder: (context) => BillScreen(tableNumber: tableId),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            builder: (context, _) => IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.black54),
              onPressed: () => _showNotifications(context, _tableService, _tableService.activeTableIds),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ListenableBuilder(
            listenable: _tableService,
            builder: (context, _) {
              final activeCount = _tableService.activeTableIds.length;
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RESTAURANT STATUS",
                          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        Text(
                          activeCount == 0 ? "All Tables Available" : "$activeCount Tables Active",
                          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onTabChange != null && widget.navigationItems != null) {
                          // Find index of reports in navigation items
                          final index = widget.navigationItems!.indexWhere((item) => item['id'] == 'reports');
                          if (index != -1) {
                            widget.onTabChange!(index);
                          } else {
                            // If reports not in navigation, maybe navigate directly or show msg
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Reports tab is not active. Enable it in settings.")),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 16, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text(
                              "Analytics",
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _syncService,
        builder: (context, child) {
          final floors = _tableService.floors;
          final tables = _tableService.tables;
          final activeSession = _syncService.activeSession;

          return RefreshIndicator(
            onRefresh: () => _tableService.fetchTables(),
            color: const Color(0xFFFFC107),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Status Card
              _buildSessionCard(activeSession),


              // Floor Selection
              if (floors.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Floor Layout",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
                              color: isSelected ? const Color(0xFFFFC107) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFFFFC107) : Theme.of(context).dividerColor.withOpacity(0.1)),
                              boxShadow: isSelected ? [
                                BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                              ] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              floor.name,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.black87 : Theme.of(context).textTheme.bodySmall?.color,
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
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
              builder: (context) => BillScreen(
                tableNumber: 1, 
                navigationItems: widget.navigationItems,
              ),
            ),
          );
          if (result is int && widget.onTabChange != null) widget.onTabChange!(result);
        },
        label: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSaaSTableCard(TableInfo table) {
    final isBooked = _tableService.isTableBooked(table.id);
    final hasItems = _tableService.getCart(table.id).isNotEmpty;
    final hasKOT = table.kotCount > 0;
    
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
        final hasActiveOrder = _tableService.isTableBooked(table.id);
        
        if (!hasActiveOrder) {
          // 1. Table status changes Vacant -> Occupied/Booked
          await _tableService.updateTableStatus(table.id, 'Occupied');
          
          // 2. Create new order -> Proceed to Place Order Page
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuScreen(
                  tableNumber: table.id,
                  navigationItems: widget.navigationItems,
                ),
              ),
            );
          }
        } else {
          // 3. Active order exists -> Resume existing order -> Go to Order Overview
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderOverviewScreen(
                  tableId: table.id,
                  tableName: table.tableId,
                  navigationItems: widget.navigationItems,
                ),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Display KOT/BOT count if exists
                  if (hasKOT) ...[
                    const SizedBox(height: 6),
                    Text(
                      "KOT: ${table.kotCount}",
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            // Amount badge in top-right corner if booked
            if (isBooked && table.totalAmount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Rs ${table.totalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic>? session) {
    if (session == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("No Active Session", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red[700])),
                  Text("Please start a session to manage orders", style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[900])),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _showStartSessionDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
              child: const Text("Start"),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Session Active", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green[700])),
                Text("Opened: ${session['start_time']}", style: GoogleFonts.poppins(fontSize: 10, color: Colors.green[800])),
              ],
            ),
          ),
          Text("Rs ${session['opening_cash']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showEndSessionDialog(),
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            tooltip: "Close Session",
          ),
        ],
      ),
    );
  }

  void _showStartSessionDialog() {
    final controller = TextEditingController(text: "0");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start POS Session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter opening cash in drawer:"),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(prefixText: "Rs ", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final cash = double.tryParse(controller.text) ?? 0.0;
              final success = await _syncService.startSession(cash);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session started successfully")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            child: const Text("Start Session"),
          ),
        ],
      ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Close POS Session?"),
        content: const Text("This will finalize all sales for this shift. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final success = await _syncService.endSession();
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session closed successfully")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Close Session"),
          ),
        ],
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
              builder: (context) => BillScreen(
                tableNumber: 1, 
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
