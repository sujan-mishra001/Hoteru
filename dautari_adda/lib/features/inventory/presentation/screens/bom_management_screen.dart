import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';

class BOMManagementScreen extends StatefulWidget {
  const BOMManagementScreen({super.key});

  @override
  State<BOMManagementScreen> createState() => _BOMManagementScreenState();
}

class _BOMManagementScreenState extends State<BOMManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _boms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final boms = await _inventoryService.getBoms();
    setState(() {
      _boms = boms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bill of Materials', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _boms.isEmpty
              ? const Center(child: Text('No BOMs defined yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _boms.length,
                  itemBuilder: (context, index) {
                    final bom = _boms[index];
                    final components = bom['components'] as List<dynamic>? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        title: Text(bom['name'] ?? 'Unnamed BOM', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${components.length} components | Output: ${bom['output_quantity']}'),
                        children: [
                          ...components.map((c) => ListTile(
                            title: Text(c['product']['name']),
                            trailing: Text('${c['quantity']} ${c['unit'] != null ? c['unit']['abbreviation'] : ''}'),
                          )),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add BOM functionality to be implemented')));
        },
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
