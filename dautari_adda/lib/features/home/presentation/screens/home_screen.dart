import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/floor_constants.dart';
import 'package:dautari_adda/features/pos/presentation/screens/order_overview_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_screen.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';
import 'package:dautari_adda/features/pos/data/session_service.dart';
import 'package:dautari_adda/core/services/sync_service.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import 'package:dautari_adda/features/inventory/data/delivery_service.dart';
import 'package:dautari_adda/features/home/presentation/widgets/customer_suggest_field.dart';
import 'package:dautari_adda/features/customers/data/customer_service.dart';
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
  final CustomerService _customerService = CustomerService();
  final SessionService _sessionService = SessionService();
  final AuthService _authService = AuthService();

  List<dynamic> _categories = [];
  bool _isLoadingMenu = true;
  int? _selectedFloorId;

  // Session state
  Map<String, dynamic>? _activeSession;
  bool _isLoadingSession = true;
  bool _isStartingSession = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadFloors();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() => _isLoadingSession = true);
    try {
      final session = await _sessionService.getActiveSession();
      if (mounted) {
        setState(() {
          _activeSession = session;
          _isLoadingSession = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSession = false);
      }
    }
  }

  Future<void> _startSession() async {
    if (_activeSession != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session already started!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController balanceController = TextEditingController(text: "0.0");
    final double? openingBalance = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start Session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter opening cash balance:"),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: "Rs ",
                border: OutlineInputBorder(),
                hintText: "0.00",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(balanceController.text) ?? 0.0;
              Navigator.pop(context, value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            child: const Text("Start Session"),
          ),
        ],
      ),
    );

    if (openingBalance == null) return;

    setState(() => _isStartingSession = true);

    try {
      final session = await _sessionService.openSession(
        openingCash: openingBalance,
        notes: "Session started from mobile app",
      );

      if (mounted) {
        setState(() {
          _activeSession = session;
          _isStartingSession = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session started successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingSession = false);
        String errorMsg = e.toString();
        if (errorMsg.contains("already has an open session")) {
          errorMsg = "You already have an active session!";
          _checkSession();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endSession() async {
    if (_activeSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No active session to end!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final sessionId = _activeSession!['id'];
    final openingCash = (_activeSession!['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final totalSales = (_activeSession!['total_sales'] as num?)?.toDouble() ?? 0.0;
    final defaultClosing = openingCash + totalSales;

    final TextEditingController closingController = TextEditingController(text: defaultClosing.toStringAsFixed(2));
    final TextEditingController notesController = TextEditingController();

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Opening Balance: Rs ${openingCash.toStringAsFixed(2)}"),
            Text("Total Sales: Rs ${totalSales.toStringAsFixed(2)}"),
            const Divider(),
            Text("Expected Closing: Rs ${defaultClosing.toStringAsFixed(2)}"),
            const SizedBox(height: 16),
            const Text("Enter actual closing balance:"),
            const SizedBox(height: 8),
            TextField(
              controller: closingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: "Rs ",
                border: OutlineInputBorder(),
                hintText: "0.00",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Notes (optional)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final closingBalance = double.tryParse(closingController.text) ?? defaultClosing;
              Navigator.pop(context, {
                'closingCash': closingBalance,
                'notes': notesController.text,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("End Session"),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isStartingSession = true);

    try {
      final success = await _sessionService.closeSession(
        sessionId: sessionId,
        closingCash: result['closingCash'],
        totalSales: totalSales,
        notes: result['notes'],
      );

      if (success && mounted) {
        setState(() {
          _activeSession = null;
          _isStartingSession = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session ended successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() => _isStartingSession = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to end session."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingSession = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSessionStatus() {
    if (_isLoadingSession) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
          ),
        ),
      );
    }

    if (_activeSession != null) {
      final startTime = _activeSession!['start_time'] != null
          ? DateTime.parse(_activeSession!['start_time'])
          : null;
      final startedBy = _activeSession!['user']?['full_name'] ?? 'Unknown';
      final openingCash = (_activeSession!['opening_cash'] as num?)?.toDouble() ?? 0.0;
      final totalSales = (_activeSession!['total_sales'] as num?)?.toDouble() ?? 0.0;

      String timeText = '';
      if (startTime != null) {
        final now = DateTime.now();
        final diff = now.difference(startTime);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        timeText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Session Active • $timeText",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Started by: $startedBy",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
                Text("Opening: Rs ${openingCash.toStringAsFixed(2)} • Sales: Rs ${totalSales.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isStartingSession ? null : _endSession,
              icon: _isStartingSession
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.stop_circle, color: Colors.white),
              label: Text(
                _isStartingSession ? "Processing..." : "End Session",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                "No active session",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isStartingSession ? null : _startSession,
            icon: _isStartingSession
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFC107)))
                : const Icon(Icons.play_circle_fill, color: Colors.black87),
            label: Text(
              _isStartingSession ? "Starting..." : "Open Session",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadFloors() async {
    await _tableService.initializationDone;

    if (_tableService.floors.isNotEmpty) {
      if (mounted) {
        setState(() {
          if (_selectedFloorId == null) {
            _selectedFloorId = _tableService.floors.first.id;
          }
        });
        if (_tableService.tables.isNotEmpty) {
          return;
        }
      }
    }

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
    await _tableService.initializationDone;

    if (_syncService.categories.isNotEmpty) {
      if (mounted) {
        setState(() {
          _categories = _syncService.categories;
          _isLoadingMenu = false;
        });
      }
      _syncService.addListener(_onSyncUpdate);
      return;
    }

    if (!_syncService.isCacheValid) {
      await _syncService.syncPOSData();
    }

    if (mounted) {
      setState(() {
        _categories = _syncService.categories;
        _isLoadingMenu = false;
      });
    }

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
    if (_selectedFloorId == null || _selectedFloorId == kHoldSectionId || _selectedFloorId == kMergeSectionId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a regular floor first")),
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

  void _showEditTableDialog(PosTable table) {
    final idController = TextEditingController(text: table.tableId);
    final capacityController = TextEditingController(text: table.capacity.toString());
    String selectedType = table.tableType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Edit Table ${table.tableId}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
            TextButton(
              onPressed: () async {
                final success = await _tableService.deleteTable(table.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Table deleted successfully"), backgroundColor: Colors.red),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.isNotEmpty) {
                  final cap = int.tryParse(capacityController.text) ?? 4;
                  final success = await _tableService.updateTable(
                    table.id,
                    {
                      'table_id': idController.text.trim(),
                      'capacity': cap,
                      'table_type': selectedType,
                      'floor_id': table.floorId,
                    },
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Table updated successfully"), backgroundColor: Colors.green),
                    );
                  }
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              child: const Text("Update Table"),
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
                                    isBooked ? "HOLD" : "DRAFT",
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
        toolbarHeight: 220,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Table Service",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                Row(
                  children: [
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildSessionStatus(),
          ],
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _tableService,
        builder: (context, child) {
          final floors = _tableService.floors;
          List<PosTable> tables;

          if (_selectedFloorId == kHoldSectionId) {
            tables = _tableService.tables.where((t) => t.isHoldTable == 'Yes').toList();
          } else if (_selectedFloorId == kMergeSectionId) {
            tables = _tableService.tables.where((t) => t.mergeGroupId != null).toList();
          } else {
            tables = _tableService.tables
                .where((t) => t.floorId == _selectedFloorId && t.isHoldTable != 'Yes' && t.mergeGroupId == null)
                .toList();
          }

          if (floors.isEmpty && _selectedFloorId != null && _selectedFloorId != kHoldSectionId && _selectedFloorId != kMergeSectionId) {
            return const Center(child: Text('No floors available. Please add floors first.'));
          }

          if (floors.isEmpty && _selectedFloorId == null) {
            return const Center(child: Text('No floors available. Please add floors first.'));
          }

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        _selectedFloorId == kMergeSectionId
                            ? "${_getMergeGroups(tables).length} Merge Groups"
                            : "${tables.length} Tables",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...floors.map((floor) {
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
                                border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFC107)
                                        : Theme.of(context).dividerColor.withOpacity(0.1)),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: const Color(0xFFFFC107).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2))
                                      ]
                                    : null,
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
                      }),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedFloorId = kHoldSectionId);
                            _tableService.fetchTables();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: _selectedFloorId == kHoldSectionId ? Colors.orange : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _selectedFloorId == kHoldSectionId
                                      ? Colors.orange
                                      : Theme.of(context).dividerColor.withOpacity(0.1)),
                              boxShadow: _selectedFloorId == kHoldSectionId
                                  ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Hold Table",
                              style: GoogleFonts.poppins(
                                color: _selectedFloorId == kHoldSectionId
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodySmall?.color,
                                fontWeight: _selectedFloorId == kHoldSectionId ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedFloorId = kMergeSectionId);
                          _tableService.fetchTables();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: _selectedFloorId == kMergeSectionId ? Colors.blue : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _selectedFloorId == kMergeSectionId
                                    ? Colors.blue
                                    : Theme.of(context).dividerColor.withOpacity(0.1)),
                            boxShadow: _selectedFloorId == kMergeSectionId
                                ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Merge Table",
                            style: GoogleFonts.poppins(
                              color:
                                  _selectedFloorId == kMergeSectionId ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: _selectedFloorId == kMergeSectionId ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _tableService.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                        : tables.isEmpty
                            ? _buildEmptyTablesState()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _loadFloors();
                                  await _loadMenu();
                                },
                                child: _selectedFloorId == kMergeSectionId
                                    ? _buildMergeSectionGrid(tables)
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
                                          return GestureDetector(
                                            onLongPress: () => _showEditTableDialog(table),
                                            child: _buildSaaSTableCard(table),
                                          );
                                        },
                                      ),
                              ),
                  ),
                ),
                _buildDeliveryTakeawayBar(),
              ],
            );
        },
      ),
    );
  }

  Widget _buildDeliveryTakeawayBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showTakeawayDialog,
                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                label: const Text('Takeaway'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFFFC107)),
                  foregroundColor: const Color(0xFFFFC107),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showDeliveryDialog,
                icon: const Icon(Icons.delivery_dining_outlined, size: 20),
                label: const Text('Delivery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFFFC107)),
                  foregroundColor: const Color(0xFFFFC107),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTakeawayDialog() {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Takeaway Order', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomerSuggestField(
                controller: nameController,
                labelText: 'Customer Name or Phone',
                hintText: 'Type name or number to search...',
                onAddCustomerRequested: () => _showAddCustomerForm(context, nameController),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final name = nameController.text.trim();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuScreen(
                              tableNumber: 0,
                              navigationItems: widget.navigationItems,
                              orderType: 'Takeaway',
                              customerName: name.isEmpty ? null : name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
                      child: const Text('Start Order'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerForm(BuildContext context, TextEditingController nameController) async {
    final nameC = TextEditingController(text: nameController.text.trim());
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    final addressC = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name'), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: addressC, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Name is required'), backgroundColor: Colors.orange));
                return;
              }
              try {
                await _customerService.createCustomer(
                  name: nameC.text.trim(),
                  phone: phoneC.text.trim(),
                  email: emailC.text.trim(),
                  address: addressC.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      nameController.text = nameC.text.trim();
    }
  }

  void _showDeliveryDialog() async {
    final partners = await DeliveryService().getDeliveryPartners();
    if (!mounted) return;

    final nameController = TextEditingController();
    int? selectedPartnerId;
    String? selectedPartnerName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Delivery Order', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (partners.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Delivery Partner',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('-- Select --')),
                        ...partners.map((p) => DropdownMenuItem(
                              value: p['id'],
                              child: Text(p['name'] ?? 'Unknown'),
                            )),
                      ],
                      onChanged: (v) => setModalState(() {
                        selectedPartnerId = v;
                        selectedPartnerName = partners.firstWhere((p) => p['id'] == v, orElse: () => {})['name'];
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomerSuggestField(
                    controller: nameController,
                    labelText: 'Customer Name or Phone',
                    hintText: 'Type name or number to search...',
                    onAddCustomerRequested: () => _showAddCustomerForm(context, nameController),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final name = nameController.text.trim();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MenuScreen(
                                  tableNumber: 0,
                                  navigationItems: widget.navigationItems,
                                  orderType: selectedPartnerId != null ? 'Delivery Partner' : 'Delivery',
                                  customerName: name.isEmpty ? null : name,
                                  deliveryPartnerId: selectedPartnerId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
                          child: const Text('Start Order'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<List<PosTable>> _getMergeGroups(List<PosTable> tables) {
    final Map<String, List<PosTable>> groups = {};
    for (final t in tables) {
      if (t.mergeGroupId != null) {
        groups.putIfAbsent(t.mergeGroupId!, () => []).add(t);
      }
    }
    return groups.values.toList();
  }

  Widget _buildMergeSectionGrid(List<PosTable> tables) {
    final mergeGroups = _getMergeGroups(tables);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: mergeGroups.length,
      itemBuilder: (context, index) {
        final group = mergeGroups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildMergedTableRectangle(group),
        );
      },
    );
  }

  Widget _buildMergedTableRectangle(List<PosTable> tablesInGroup) {
    final tableIds = tablesInGroup.map((t) => t.tableId).join(' + ');
    final primaryTable = tablesInGroup.first;
    final isBooked = tablesInGroup.any((t) => _tableService.isTableBooked(t.id));
    final totalAmount = tablesInGroup.fold<double>(0, (sum, t) => sum + t.totalAmount);
    final statusColor = isBooked ? Colors.indigo : Colors.blue;

    return InkWell(
      onTap: () async {
        if (isBooked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderOverviewScreen(
                tableId: primaryTable.id,
                tableName: 'Merged: $tableIds',
                navigationItems: widget.navigationItems,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                tableNumber: primaryTable.id,
                navigationItems: widget.navigationItems,
              ),
            ),
          );
        }
      },
      onLongPress: () => _showMergeGroupOptionsDialog(tablesInGroup),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.merge_type, size: 32, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merged: $tableIds',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBooked ? 'HOLD' : 'MERGED',
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (totalAmount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Total: NPR ${totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFFC107),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showMergeGroupOptionsDialog(List<PosTable> tablesInGroup) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call_split, color: Colors.blue),
              title: const Text('Unmerge Tables'),
              onTap: () async {
                Navigator.pop(context);
                final mgId = tablesInGroup.first.mergeGroupId;
                if (mgId != null) {
                  final success = await _tableService.unmergeTables(mgId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Tables unmerged' : 'Unmerge failed')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaaSTableCard(PosTable table) {
    final isBooked = _tableService.isTableBooked(table.id);
    final hasItems = _tableService.getCart(table.id).isNotEmpty;
    final hasKOT = table.kotCount > 0;

    Color statusColor = const Color(0xFF10B981); // Green (Vacant)
    String statusText = "VACANT";

    if (table.isHoldTable == 'Yes') {
      statusColor = Colors.orange;
      statusText = "VACANT (HOLD)";
      if (isBooked) {
        statusColor = Colors.deepOrange;
        statusText = "HOLD";
      }
    } else if (table.mergeGroupId != null) {
      statusColor = Colors.blue;
      statusText = "MERGED";
      if (isBooked) statusColor = Colors.indigo;
      if (isBooked) statusText = "HOLD";
    } else if (isBooked) {
      statusColor = const Color(0xFFEF4444);
      statusText = "HOLD";
    }

    return InkWell(
      onTap: () async {
        final hasActiveOrder = _tableService.isTableBooked(table.id);
        if (!hasActiveOrder) {
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
            if (table.isHoldTable == 'Yes' || table.mergeGroupId != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: table.isHoldTable == 'Yes' ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    table.isHoldTable == 'Yes' ? 'HOLD' : 'MERGED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) async {
                  if (value == 'hold') {
                    bool newStatus = table.isHoldTable != 'Yes';
                    await _tableService.setHoldTable(table.id, newStatus);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(newStatus ? "Table set to Hold" : "Hold removed")),
                      );
                    }
                  } else if (value == 'merge') {
                    _showMergeTableDialog(table);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'hold',
                    child: Row(
                      children: [
                        Icon(table.isHoldTable == 'Yes' ? Icons.timer_off : Icons.timer, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(table.isHoldTable == 'Yes' ? 'Remove Hold' : 'Set as Hold Table'),
                      ],
                    ),
                  ),
                  if (table.mergeGroupId == null)
                    const PopupMenuItem<String>(
                      value: 'merge',
                      child: Row(
                        children: [
                          Icon(Icons.merge_type, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Merge with...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
                    child: Icon(
                        table.isHoldTable == 'Yes' ? Icons.pause_circle_filled : Icons.table_bar_rounded,
                        size: 24,
                        color: statusColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    table.tableId,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (table.totalAmount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "NPR ${table.totalAmount.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (isBooked && table.totalAmount > 0)
              Positioned(
                top: 6,
                left: 6,
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
          if (_selectedFloorId != null && _selectedFloorId != kHoldSectionId && _selectedFloorId != kMergeSectionId)
            ElevatedButton(
              onPressed: _showAddTableDialog,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
              child: const Text("Add First Table"),
            ),
        ],
      ),
    );
  }

  void _showMergeTableDialog(PosTable primaryTable) {
    final availableTables = _tableService.tables
        .where((t) =>
            t.id != primaryTable.id &&
            t.mergeGroupId == null &&
            t.isHoldTable != 'Yes' &&
            _tableService.isTableBooked(t.id) == false)
        .toList();

    final List<int> selectedIds = [];

    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No available tables to merge with.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Merge ${primaryTable.tableId} with..."),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTables.length,
              itemBuilder: (context, index) {
                final t = availableTables[index];
                return CheckboxListTile(
                  title: Text(t.tableId),
                  value: selectedIds.contains(t.id),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selectedIds.add(t.id);
                      } else {
                        selectedIds.remove(t.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedIds.isEmpty) return;
                Navigator.pop(context);
                final success = await _tableService.mergeTables(primaryTable.id, selectedIds);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tables Merged Successfully")));
                } else if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Merge Failed"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Merge"),
            ),
          ],
        ),
      ),
    );
  }
}