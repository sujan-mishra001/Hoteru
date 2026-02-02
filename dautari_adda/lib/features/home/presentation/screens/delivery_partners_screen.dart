import 'package:flutter/material.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:dautari_adda/features/home/data/delivery_service.dart';

class DeliveryPartnersScreen extends StatefulWidget {
  const DeliveryPartnersScreen({super.key});

  @override
  State<DeliveryPartnersScreen> createState() => _DeliveryPartnersScreenState();
}

class _DeliveryPartnersScreenState extends State<DeliveryPartnersScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  bool _isLoading = false;
  List<dynamic> _partners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    try {
      _partners = await _deliveryService.getDeliveryPartners();
    } catch (e) {
      ToastService.showError('Failed to load delivery partners');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partners'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No delivery partners found'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Partner'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _partners.length,
                  itemBuilder: (context, index) {
                    final partner = _partners[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping, color: Colors.blue),
                        title: Text(partner['name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (partner['phone'] != null) Text('Phone: ${partner['phone']}'),
                            if (partner['vehicle_number'] != null) Text('Vehicle: ${partner['vehicle_number']}'),
                            if (partner['status'] != null) Text('Status: ${partner['status']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showEditDialog(partner),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(partner),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final vehicleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Delivery Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: vehicleController, decoration: const InputDecoration(labelText: 'Vehicle Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ToastService.showError('Name is required');
                return;
              }
              
              final success = await _deliveryService.createDeliveryPartner({
                'name': nameController.text,
                'phone': phoneController.text,
                'vehicle_number': vehicleController.text,
              });
              
              if (success) {
                ToastService.showSuccess('Partner added successfully');
                _loadPartners();
              } else {
                ToastService.showError('Failed to add partner');
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(dynamic partner) {
    final nameController = TextEditingController(text: partner['name']);
    final phoneController = TextEditingController(text: partner['phone']);
    final vehicleController = TextEditingController(text: partner['vehicle_number']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Delivery Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: vehicleController, decoration: const InputDecoration(labelText: 'Vehicle Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _deliveryService.updateDeliveryPartner(partner['id'], {
                'name': nameController.text,
                'phone': phoneController.text,
                'vehicle_number': vehicleController.text,
              });
              
              if (success) {
                ToastService.showSuccess('Partner updated successfully');
                _loadPartners();
              } else {
                ToastService.showError('Failed to update partner');
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text('Are you sure you want to delete "${partner['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await _deliveryService.deleteDeliveryPartner(partner['id']);
              if (success) {
                ToastService.showSuccess('Partner deleted successfully');
                _loadPartners();
              } else {
                ToastService.showError('Failed to delete partner');
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
