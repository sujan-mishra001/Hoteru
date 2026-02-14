import 'package:flutter/material.dart';
import 'package:dautari_adda/features/inventory/data/inventory_service.dart';

class AddBOMScreen extends StatefulWidget {
  final Map<String, dynamic>? initialBOM;
  const AddBOMScreen({super.key, this.initialBOM});

  @override
  State<AddBOMScreen> createState() => _AddBOMScreenState();
}

class _AddBOMScreenState extends State<AddBOMScreen> {
  final InventoryService _inventoryService = InventoryService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _outputQtyController = TextEditingController(text: '1.0');
  int? _selectedFinishedProductId;
  
  List<Map<String, dynamic>> _components = [];
  List<dynamic> _products = [];
  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialBOM != null) {
      _nameController.text = widget.initialBOM!['name'] ?? '';
      _outputQtyController.text = widget.initialBOM!['output_quantity']?.toString() ?? '1.0';
      _selectedFinishedProductId = widget.initialBOM!['finished_product_id'];
      final initialComponents = widget.initialBOM!['components'] as List<dynamic>? ?? [];
      for (var comp in initialComponents) {
        _components.add({
          'product_id': comp['product_id'],
          'unit_id': comp['unit_id'],
          'quantity': comp['quantity']?.toString() ?? '0.0',
        });
      }
    } else {
      _addComponent();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _inventoryService.getProducts();
    _units = await _inventoryService.getUnits();
    setState(() => _isLoading = false);
  }

  void _addComponent() {
    setState(() {
      _components.add({
        'product_id': null,
        'unit_id': null,
        'quantity': '1.0',
      });
    });
  }

  void _removeComponent(int index) {
    setState(() {
      _components.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one component')));
      return;
    }

    final data = {
      'name': _nameController.text,
      'output_quantity': double.tryParse(_outputQtyController.text) ?? 1.0,
      'finished_product_id': _selectedFinishedProductId,
      'is_active': true,
      'components': _components.map((c) => {
        'product_id': c['product_id'],
        'unit_id': c['unit_id'],
        'quantity': double.tryParse(c['quantity']) ?? 0.0,
      }).toList(),
    };

    bool success;
    if (widget.initialBOM != null) {
      success = await _inventoryService.updateBom(widget.initialBOM!['id'], data);
    } else {
      success = await _inventoryService.createBom(data);
    }

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save BOM')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.initialBOM != null ? 'Edit BOM' : 'Create BOM', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.black),
            onPressed: _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('General Information'),
                  _buildCard([
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'BOM Name (e.g. Tomato Sauce Recipe)', prefixIcon: Icon(Icons.title)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _outputQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Output Quantity', prefixIcon: Icon(Icons.scale)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedFinishedProductId,
                      decoration: const InputDecoration(labelText: 'Finished Product (Optional)', prefixIcon: Icon(Icons.inventory)),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('No Finished Product')),
                        ..._products.map((p) => DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text(p['name']),
                        )),
                      ],
                      onChanged: (val) => setState(() => _selectedFinishedProductId = val),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Components'),
                      TextButton.icon(
                        onPressed: _addComponent,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  ..._components.asMap().entries.map((entry) => _buildComponentCard(entry.key, entry.value)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildComponentCard(int index, Map<String, dynamic> component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  value: component['product_id'],
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Product', border: InputBorder.none),
                  items: _products.map((p) => DropdownMenuItem<int>(
                    value: p['id'],
                    child: Text(p['name'], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) => setState(() => component['product_id'] = val),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                onPressed: () => _removeComponent(index),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: component['quantity'],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity', border: InputBorder.none),
                  onChanged: (val) => component['quantity'] = val,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: component['unit_id'],
                  decoration: const InputDecoration(labelText: 'Unit', border: InputBorder.none),
                  items: _units.map((u) => DropdownMenuItem<int>(
                    value: u['id'],
                    child: Text(u['abbreviation'], style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (val) => setState(() => component['unit_id'] = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
