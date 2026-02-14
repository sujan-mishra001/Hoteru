import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';

class FloorsTablesManagementScreen extends StatefulWidget {
  const FloorsTablesManagementScreen({super.key});

  @override
  State<FloorsTablesManagementScreen> createState() => _FloorsTablesManagementScreenState();
}

class _FloorsTablesManagementScreenState extends State<FloorsTablesManagementScreen> with TickerProviderStateMixin {
  final TableService _tableService = TableService();
  String _searchQuery = '';
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tableService.addListener(_handleTableServiceUpdate);
    _loadData();
  }

  @override
  void dispose() {
    _tableService.removeListener(_handleTableServiceUpdate);
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTableServiceUpdate() {
    if (mounted) {
      _updateTabController();
    }
  }

  Future<void> _loadData() async {
    await _tableService.fetchFloors();
    await _tableService.fetchTables();
    _updateTabController();
  }

  void _updateTabController() {
    final floorCount = _tableService.floors.length;
    if (_tabController == null || _tabController!.length != floorCount) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
        length: floorCount > 0 ? floorCount : 1,
        vsync: this,
        initialIndex: (oldIndex < floorCount) ? oldIndex : 0,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final floors = _tableService.floors;
    final isLoading = _tableService.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(floors),
      body: isLoading && floors.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : floors.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildFloorTabs(floors),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: floors.map((floor) => _buildTableGrid(floor.id)).toList(),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFFFFC107),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.black87),
        label: Text(
          "Manage",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(List<FloorInfo> floors) {
    return AppBar(
      backgroundColor: const Color(0xFFFFC107),
      elevation: 0,
      title: Text(
        'Table Management',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search tables...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorTabs(List<FloorInfo> floors) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: TabBar(
        controller: _tabController,
        isScrollable: floors.length > 3,
        indicatorColor: const Color(0xFFFFC107),
        indicatorWeight: 3,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: floors.map((f) => Tab(text: f.name)).toList(),
      ),
    );
  }

  Widget _buildTableGrid(int floorId) {
    final filteredTables = _tableService.tables.where((t) {
      final matchesFloor = t.floorId == floorId;
      final matchesSearch = t.tableId.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFloor && matchesSearch && t.isHoldTable != 'Yes';
    }).toList();

    if (filteredTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No tables found in this floor",
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _tableService.fetchTables(force: true),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: filteredTables.length,
        itemBuilder: (context, index) {
          final table = filteredTables[index];
          return _buildTableCard(table);
        },
      ),
    );
  }

  Widget _buildTableCard(PosTable table) {
    final isBooked = _tableService.isTableBooked(table.id);
    final statusColor = isBooked ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BillScreen(tableNumber: table.id)),
        );
      },
      onLongPress: () => _showTableOptions(table),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
              child: Icon(Icons.table_bar_rounded, color: statusColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              table.tableId,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              isBooked ? 'Booked' : 'Available',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.layers_clear_outlined, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            "No Floors Configured",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Add floors first to manage tables",
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddFloorDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add First Floor"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Management Actions", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.add_business_rounded, color: Colors.blue),
              title: const Text("Add New Floor"),
              onTap: () {
                Navigator.pop(context);
                _showAddFloorDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_bar_rounded, color: Colors.green),
              title: const Text("Add New Table"),
              onTap: () {
                Navigator.pop(context);
                _showAddTableDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_road_rounded, color: Colors.orange),
              title: const Text("Manage Floors"),
              onTap: () {
                Navigator.pop(context);
                _showManageFloorsDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddFloorDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Floor"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Floor Name (e.g. Roof Top)"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final success = await _tableService.createFloor(controller.text.trim());
              if (success && mounted) {
                ToastService.showSuccess(context, "Floor created");
                _loadData();
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog() {
    if (_tableService.floors.isEmpty) {
      ToastService.showError(context, "Add a floor first");
      return;
    }

    final idController = TextEditingController();
    int? selectedFloorId = _tabController != null && _tableService.floors.isNotEmpty 
        ? _tableService.floors[_tabController!.index].id 
        : _tableService.floors.first.id;
    int capacity = 4;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Table"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: "Table ID (e.g. T1)"),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedFloorId,
                decoration: const InputDecoration(labelText: "Floor"),
                items: _tableService.floors.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                onChanged: (v) => selectedFloorId = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Capacity (Seats)"),
                keyboardType: TextInputType.number,
                onChanged: (v) => capacity = int.tryParse(v) ?? 4,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.isEmpty || selectedFloorId == null) return;
                final success = await _tableService.createTable(
                  idController.text.trim(),
                  selectedFloorId!,
                  capacity: capacity,
                );
                if (success && mounted) {
                  ToastService.showSuccess(context, "Table created");
                  _tableService.fetchTables();
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageFloorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manage Floors"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _tableService.floors.length,
            itemBuilder: (context, index) {
              final floor = _tableService.floors[index];
              return ListTile(
                title: Text(floor.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditFloorDialog(floor);
                        }),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteFloor(floor);
                        }),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showEditFloorDialog(FloorInfo floor) {
    final controller = TextEditingController(text: floor.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Floor"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final success = await _tableService.updateFloor(floor.id, controller.text.trim());
              if (success && mounted) {
                ToastService.showSuccess(context, "Floor updated");
                _loadData();
              }
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFloor(FloorInfo floor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Floor"),
        content: Text("Are you sure you want to delete '${floor.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await _tableService.deleteFloor(floor.id);
              if (success && mounted) {
                ToastService.showSuccess(context, "Floor deleted");
                _loadData();
              }
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showTableOptions(PosTable table) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text("Edit Table"),
              onTap: () {
                Navigator.pop(context);
                _showEditTableDialog(table);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Table"),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteTable(table);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTableDialog(PosTable table) {
    final idController = TextEditingController(text: table.tableId);
    final capController = TextEditingController(text: table.capacity.toString());
    int? selectedFloorId = table.floorId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Table"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idController, decoration: const InputDecoration(labelText: "Table ID")),
            const SizedBox(height: 12),
            TextField(controller: capController, decoration: const InputDecoration(labelText: "Capacity"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final success = await _tableService.updateTable(table.id, {
                'table_id': idController.text.trim(),
                'capacity': int.tryParse(capController.text) ?? table.capacity,
                'floor_id': table.floorId,
              });
              if (success && mounted) {
                ToastService.showSuccess(context, "Table updated");
                _tableService.fetchTables();
              }
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTable(PosTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Table"),
        content: Text("Are you sure you want to delete ${table.tableId}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await _tableService.deleteTable(table.id);
              if (success && mounted) {
                ToastService.showSuccess(context, "Table deleted");
              }
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
