import 'package:flutter/material.dart';
import 'package:dautari_adda/features/pos/presentation/screens/bill_screen.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:dautari_adda/features/pos/data/floor_table_service.dart';

class FloorsTablesManagementScreen extends StatefulWidget {
  const FloorsTablesManagementScreen({super.key});

  @override
  State<FloorsTablesManagementScreen> createState() => _FloorsTablesManagementScreenState();
}

class _FloorsTablesManagementScreenState extends State<FloorsTablesManagementScreen> {
  final FloorTableService _service = FloorTableService();
  bool _isLoading = false;
  List<dynamic> _floors = [];
  List<dynamic> _tables = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getFloors(),
        _service.getTables(),
      ]);
      
      setState(() {
        _floors = results[0];
        _tables = results[1];
      });
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Failed to load data');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          title: const Text(
            'Floors & Tables',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          backgroundColor: const Color(0xFFFFC107),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Floors Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Floors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: _showAddFloorDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _floors.isEmpty
                      ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No floors added')))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _floors.map((floor) => Chip(
                            label: Text(floor['name'] ?? 'Unknown'),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _confirmDeleteFloor(floor),
                          )).toList(),
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Tables Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: _showAddTableDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _tables.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('No tables added', textAlign: TextAlign.center),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _tables.length,
                          itemBuilder: (context, index) {
                            final table = _tables[index];
                            final status = table['status'] ?? 'Available';
                            Color statusColor = Colors.green;
                            if (status == 'Occupied') statusColor = Colors.red;
                            else if (status == 'Reserved') statusColor = Colors.orange;
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BillScreen(tableNumber: table['id']),
                                  ),
                                );
                              },
                              onLongPress: () => _showTableOptions(table),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.table_restaurant,
                                      color: statusColor,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      table['table_id']?.toString() ?? 'T${table['id']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      status,
                                      style: TextStyle(fontSize: 10, color: statusColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  void _showAddFloorDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Floor'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Floor Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ToastService.showError(context, 'Floor name is required');
                return;
              }
              
              final success = await _service.createFloor({
                'name': nameController.text,
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Floor added successfully');
                _loadData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to add floor');
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog() {
    final tableIdController = TextEditingController();
    int? selectedFloorId;
    int seats = 4;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableIdController,
              decoration: const InputDecoration(labelText: 'Table ID/Number'),
            ),
            DropdownButtonFormField<int>(
              value: selectedFloorId,
              decoration: const InputDecoration(labelText: 'Floor'),
              items: _floors.map<DropdownMenuItem<int>>((f) {
                return DropdownMenuItem<int>(
                  value: f['id'] as int,
                  child: Text(f['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) => selectedFloorId = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Number of Seats'),
              keyboardType: TextInputType.number,
              onChanged: (value) => seats = int.tryParse(value) ?? 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (tableIdController.text.isEmpty || selectedFloorId == null) {
                ToastService.showError(context, 'Please fill all fields');
                return;
              }
              
              final success = await _service.createTable({
                'table_id': tableIdController.text,
                'floor_id': selectedFloorId,
                'seats': seats,
                'status': 'Available',
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Table added successfully');
                _loadData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to add table');
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTableOptions(dynamic table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Table ${table['table_id'] ?? table['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Table'),
              onTap: () {
                Navigator.pop(context);
                _showEditTableDialog(table);
              },
            ),
            ListTile(
              leading: const Icon(Icons.update, color: Colors.blue),
              title: const Text('Change Status'),
              onTap: () {
                Navigator.pop(context);
                _showChangeStatusDialog(table);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Table'),
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

  void _showEditTableDialog(dynamic table) {
    final tableIdController = TextEditingController(text: table['table_id']?.toString());
    final seatsController = TextEditingController(text: table['seats']?.toString() ?? '4');
    int seats = table['seats'] ?? 4;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableIdController,
              decoration: const InputDecoration(labelText: 'Table ID/Number'),
            ),
            TextField(
              controller: seatsController,
              decoration: const InputDecoration(labelText: 'Number of Seats'),
              keyboardType: TextInputType.number,
              onChanged: (value) => seats = int.tryParse(value) ?? 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _service.updateTable(table['id'], {
                'table_id': tableIdController.text,
                'seats': seats,
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Table updated successfully');
                _loadData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to update table');
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(dynamic table) {
    String selectedStatus = table['status'] ?? 'Available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Table Status'),
        content: DropdownButtonFormField<String>(
          value: selectedStatus,
          decoration: const InputDecoration(labelText: 'Status'),
          items: ['Available', 'Occupied', 'Reserved', 'Maintenance'].map((status) => DropdownMenuItem(
            value: status,
            child: Text(status),
          )).toList(),
          onChanged: (value) => selectedStatus = value!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _service.updateTableStatus(table['id'], selectedStatus);
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Status updated successfully');
                _loadData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to update status');
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFloor(dynamic floor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Floor'),
        content: Text('Are you sure you want to delete "${floor['name']}"? This will not delete associated tables.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await _service.deleteFloor(floor['id']);
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Floor deleted successfully');
                _loadData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to delete floor');
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTable(dynamic table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete Table ${table['table_id'] ?? table['id']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await _service.deleteTable(table['id']);
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Table deleted successfully');
                _loadData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to delete table');
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
