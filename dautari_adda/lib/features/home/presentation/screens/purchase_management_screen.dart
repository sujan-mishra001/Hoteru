import 'package:flutter/material.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:dautari_adda/features/home/data/purchase_service.dart';

class PurchaseManagementScreen extends StatefulWidget {
  const PurchaseManagementScreen({super.key});

  @override
  State<PurchaseManagementScreen> createState() => _PurchaseManagementScreenState();
}

class _PurchaseManagementScreenState extends State<PurchaseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PurchaseService _purchaseService = PurchaseService();
  
  bool _isLoading = false;
  List<dynamic> _suppliers = [];
  List<dynamic> _purchaseBills = [];
  List<dynamic> _purchaseReturns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _purchaseService.getSuppliers(),
        _purchaseService.getPurchaseBills(),
        _purchaseService.getPurchaseReturns(),
      ]);
      
      setState(() {
        _suppliers = results[0];
        _purchaseBills = results[1];
        _purchaseReturns = results[2];
      });
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Failed to load data');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Suppliers'),
            Tab(text: 'Bills'),
            Tab(text: 'Returns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuppliersTab(),
          _buildBillsTab(),
          _buildReturnsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(_tabController.index),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _suppliers.length,
          itemBuilder: (context, index) {
            final supplier = _suppliers[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.business, color: Colors.blue),
                title: Text(supplier['name'] ?? 'Unknown'),
                subtitle: Text(supplier['contact_person'] ?? supplier['phone'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showEditSupplierDialog(supplier),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteSupplier(supplier),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildBillsTab() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _purchaseBills.length,
          itemBuilder: (context, index) {
            final bill = _purchaseBills[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.receipt, color: Colors.green),
                title: Text(bill['bill_number'] ?? 'Unknown'),
                subtitle: Text('Supplier: ${bill['supplier']?['name'] ?? 'N/A'}'),
                trailing: Text(
                  'Rs. ${(bill['total_amount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            );
          },
        );
  }

  Widget _buildReturnsTab() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _purchaseReturns.length,
          itemBuilder: (context, index) {
            final ret = _purchaseReturns[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.undo, color: Colors.red),
                title: Text(ret['return_number'] ?? 'Unknown'),
                subtitle: Text('Bill: ${ret['purchase_bill']?['bill_number'] ?? 'N/A'}'),
                trailing: Text(
                  'Rs. ${(ret['amount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            );
          },
        );
  }

  void _showAddDialog(int tabIndex) {
    switch (tabIndex) {
      case 0:
        _showAddSupplierDialog();
        break;
      case 1:
        _showAddBillDialog();
        break;
      case 2:
        _showAddReturnDialog();
        break;
    }
  }

  // Supplier Dialogs
  void _showAddSupplierDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ToastService.showError(context, 'Name is required');
                return;
              }
              
              final success = await _purchaseService.createSupplier({
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'address': addressController.text,
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Supplier added successfully');
                _loadAllData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to add supplier');
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(dynamic supplier) {
    final nameController = TextEditingController(text: supplier['name']);
    final phoneController = TextEditingController(text: supplier['phone']);
    final emailController = TextEditingController(text: supplier['email']);
    final addressController = TextEditingController(text: supplier['address']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _purchaseService.updateSupplier(supplier['id'], {
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'address': addressController.text,
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Supplier updated successfully');
                _loadAllData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to update supplier');
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(dynamic supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "${supplier['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await _purchaseService.deleteSupplier(supplier['id']);
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Supplier deleted successfully');
                _loadAllData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to delete supplier');
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Purchase Bill Dialog
  void _showAddBillDialog() {
    final billNumberController = TextEditingController();
    final amountController = TextEditingController();
    int? selectedSupplierId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Purchase Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: billNumberController, decoration: const InputDecoration(labelText: 'Bill Number')),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<int>(
              value: selectedSupplierId,
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: _suppliers.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem<int>(
                  value: s['id'] as int,
                  child: Text(s['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) => selectedSupplierId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty || selectedSupplierId == null) {
                ToastService.showError(context, 'Please fill all fields');
                return;
              }
              
              final success = await _purchaseService.createPurchaseBill({
                'bill_number': billNumberController.text,
                'total_amount': double.tryParse(amountController.text) ?? 0,
                'supplier_id': selectedSupplierId,
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Purchase bill created successfully');
                _loadAllData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to create purchase bill');
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Purchase Return Dialog
  void _showAddReturnDialog() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    int? selectedBillId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Purchase Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedBillId,
              decoration: const InputDecoration(labelText: 'Purchase Bill'),
              items: _purchaseBills.map<DropdownMenuItem<int>>((b) {
                return DropdownMenuItem<int>(
                  value: b['id'] as int,
                  child: Text(b['bill_number'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) => selectedBillId = value,
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Return Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Return Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty || selectedBillId == null) {
                ToastService.showError(context, 'Please fill all fields');
                return;
              }
              
              final success = await _purchaseService.createPurchaseReturn({
                'purchase_bill_id': selectedBillId,
                'amount': double.tryParse(amountController.text) ?? 0,
                'reason': reasonController.text,
              });
              
              if (success) {
                if (mounted) ToastService.showSuccess(context, 'Purchase return created successfully');
                _loadAllData();
              } else {
                if (mounted) ToastService.showError(context, 'Failed to create purchase return');
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
