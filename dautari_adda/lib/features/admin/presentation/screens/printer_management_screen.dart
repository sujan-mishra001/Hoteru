import 'package:flutter/material.dart';
import 'package:dautari_adda/features/profile/data/printer_service.dart';
import 'package:dautari_adda/core/services/printing_service.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart' as hardware;
import 'package:flutter_thermal_printer/utils/printer.dart' as hardware;
import 'package:dautari_adda/core/utils/toast_service.dart';

class PrinterManagementScreen extends StatefulWidget {
  const PrinterManagementScreen({super.key});

  @override
  State<PrinterManagementScreen> createState() => _PrinterManagementScreenState();
}

class _PrinterManagementScreenState extends State<PrinterManagementScreen> {
  final PrinterService _apiService = PrinterService();
  final PrintingService _hardwareService = PrintingService();
  
  List<dynamic> _backendPrinters = [];
  List<hardware.Printer> _discoveredPrinters = [];
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    final printers = await _apiService.getPrinters();
    setState(() {
      _backendPrinters = printers;
      _isLoading = false;
    });
  }

  Future<void> _scanPrinters() async {
    setState(() => _isScanning = true);
    try {
      await _hardwareService.scanPrinters();
      setState(() {
        _discoveredPrinters = _hardwareService.devices;
      });
    } catch (e) {
      ToastService.showError(context, 'Failed to scan printers: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _addPrinter(hardware.Printer hardwarePrinter) async {
    // Show dialog to name the printer
    final result = await _showPrinterDetailsDialog(hardwarePrinter);
    if (result != null) {
      final success = await _apiService.createPrinter({
        'name': result['name'],
        'ip_address': hardwarePrinter.address,
        'connection_type': hardwarePrinter.connectionType?.name.toLowerCase() ?? 'network',
        'paper_size': result['paper_size'],
        'is_active': true,
      });

      if (success != null) {
        ToastService.showSuccess(context, 'Printer added successfully');
        _loadPrinters();
      } else {
        ToastService.showError(context, 'Failed to save printer to backend');
      }
    }
  }

  Future<void> _manualAddPrinter() async {
    final result = await _showPrinterDetailsDialog(null, isManual: true);
    if (result != null) {
      final success = await _apiService.createPrinter({
        'name': result['name'],
        'ip_address': result['ip_address'],
        'port': result['port'] ?? 9100,
        'connection_type': result['connection_type'],
        'paper_size': result['paper_size'],
        'is_active': true,
      });

      if (success != null) {
        ToastService.showSuccess(context, 'Printer added successfully');
        _loadPrinters();
      } else {
        ToastService.showError(context, 'Failed to save printer to backend');
      }
    }
  }

  Future<void> _deletePrinter(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Printer'),
        content: const Text('Are you sure you want to remove this printer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deletePrinter(id);
      if (success) {
        ToastService.showSuccess(context, 'Printer deleted');
        _loadPrinters();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: AppBar(
            title: const Text(
              'Printer Management',
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
            bottom: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              tabs: [
                Tab(text: 'My Printers'),
                Tab(text: 'Discover'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyPrintersList(),
            _buildDiscoverPrintersList(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _manualAddPrinter,
          backgroundColor: const Color(0xFFFFC107),
          child: const Icon(Icons.add, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildMyPrintersList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)));
    if (_backendPrinters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_disabled_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No printers configured', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => DefaultTabController.of(context).animateTo(1),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              child: const Text('Discover Printers', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _backendPrinters.length,
      itemBuilder: (context, index) {
        final p = _backendPrinters[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFC107).withOpacity(0.1),
              child: const Icon(Icons.print_rounded, color: Color(0xFFFFC107)),
            ),
            title: Text(p['name'] ?? 'Unnamed Printer', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${p['connection_type']} • ${p['ip_address'] ?? 'USB'} • ${p['paper_size']}mm'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deletePrinter(p['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverPrintersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Hardware', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanPrinters,
                icon: _isScanning 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.search, size: 18, color: Colors.black87),
                label: Text(_isScanning ? 'Scanning...' : 'Scan', style: const TextStyle(color: Colors.black87)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _discoveredPrinters.isEmpty
              ? Center(
                  child: Text(_isScanning ? 'Looking for printers...' : 'No printers found. Try scanning.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _discoveredPrinters.length,
                  itemBuilder: (context, index) {
                    final p = _discoveredPrinters[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          p.connectionType == hardware.ConnectionType.USB ? Icons.usb : Icons.network_check,
                          color: Colors.blue,
                        ),
                        title: Text(p.name ?? 'Unknown Device'),
                        subtitle: Text(p.address ?? 'No Address'),
                        trailing: ElevatedButton(
                          onPressed: () => _addPrinter(p),
                          child: const Text('Add'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _showPrinterDetailsDialog(hardware.Printer? hp, {bool isManual = false}) async {
    String name = hp?.name ?? '';
    String ip = hp?.address ?? '';
    String port = '9100';
    String connectionType = hp?.connectionType?.name.toLowerCase() ?? 'network';
    int paperSize = 80;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isManual ? 'Add Printer Manually' : 'Printer Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Printer Name (e.g. Kitchen)'),
                      onChanged: (v) => name = v,
                      controller: TextEditingController(text: name),
                    ),
                    if (isManual) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: connectionType,
                        decoration: const InputDecoration(labelText: 'Connection Type'),
                        items: const [
                          DropdownMenuItem(value: 'network', child: Text('Network (IP)')),
                          DropdownMenuItem(value: 'usb', child: Text('USB')),
                        ],
                        onChanged: (v) => setDialogState(() => connectionType = v!),
                      ),
                      if (connectionType == 'network') ...[
                        TextField(
                          decoration: const InputDecoration(labelText: 'IP Address'),
                          onChanged: (v) => ip = v,
                        ),
                        TextField(
                          decoration: const InputDecoration(labelText: 'Port (default 9100)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => port = v,
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: paperSize,
                      decoration: const InputDecoration(labelText: 'Paper Size'),
                      items: const [
                        DropdownMenuItem(value: 80, child: Text('80mm')),
                        DropdownMenuItem(value: 58, child: Text('58mm')),
                      ],
                      onChanged: (v) => paperSize = v!,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (name.isEmpty) {
                      ToastService.showError(context, 'Please enter a printer name');
                      return;
                    }
                    Navigator.pop(context, {
                      'name': name,
                      'ip_address': ip,
                      'port': int.tryParse(port) ?? 9100,
                      'connection_type': connectionType,
                      'paper_size': paperSize,
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
                  child: const Text('Save', style: TextStyle(color: Colors.black87)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
