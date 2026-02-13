import 'package:flutter/material.dart';
import 'package:dautari_adda/features/admin/data/branch_service.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final BranchService _branchService = BranchService();
  
  List<dynamic> _branches = [];
  bool _isLoading = true;
  bool _isAdmin = true; // TODO: Get from auth service

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    _branches = await _branchService.getBranches();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Text('Branch Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddBranchDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBranches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_city, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No branches found'),
                      if (_isAdmin)
                        ElevatedButton(
                          onPressed: () => _showAddBranchDialog(),
                          child: const Text('Add First Branch'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    return _buildBranchCard(branch);
                  },
                ),
    );
  }

  Widget _buildBranchCard(dynamic branch) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFFFC107),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch['name'] ?? 'Unknown Branch',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Code: ${branch['code'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, size: 28),
                        color: Colors.green,
                        onPressed: () => _selectBranch(branch['id']),
                        tooltip: 'Select Branch',
                      ),
                      if (_isAdmin)
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleMenuAction(value, branch),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Branch'),
                            ),
                            const PopupMenuItem(
                              value: 'users',
                              child: Text('Manage Users'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Branch'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Branch details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (branch['address'] != null) ...[
                    _buildDetailRow(Icons.location_on, 'Address', branch['address']),
                    const SizedBox(height: 12),
                  ],
                  if (branch['phone'] != null) ...[
                    _buildDetailRow(Icons.phone, 'Phone', branch['phone']),
                    const SizedBox(height: 12),
                  ],
                  if (branch['email'] != null) ...[
                    _buildDetailRow(Icons.email, 'Email', branch['email']),
                    const SizedBox(height: 12),
                  ],
                  // Additional info
                  _buildDetailRow(
                    Icons.business,
                    'Branch ID',
                    '#${branch['id'].toString()}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, dynamic branch) {
    switch (action) {
      case 'edit':
        _showEditBranchDialog(branch);
        break;
      case 'users':
        _showManageUsersDialog(branch);
        break;
      case 'delete':
        _confirmDeleteBranch(branch);
        break;
    }
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Branch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Branch Code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _branchService.createBranch(
                  name: nameController.text,
                  code: codeController.text,
                  address: addressController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                );
                Navigator.pop(context);
                _loadBranches();
                _showSuccessSnackBar('Branch created successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Create Branch'),
          ),
        ],
      ),
    );
  }

  void _showEditBranchDialog(dynamic branch) {
    final nameController = TextEditingController(text: branch['name']);
    final addressController = TextEditingController(text: branch['address']);
    final phoneController = TextEditingController(text: branch['phone']);
    final emailController = TextEditingController(text: branch['email']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Branch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _branchService.updateBranch(branch['id'], {
                  'name': nameController.text,
                  'address': addressController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                });
                Navigator.pop(context);
                _loadBranches();
                _showSuccessSnackBar('Branch updated successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showManageUsersDialog(dynamic branch) async {
    final users = await _branchService.getBranchUsers(branch['id']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Users in ${branch['name']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: users.isEmpty
              ? const Center(child: Text('No users assigned to this branch'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFFC107),
                        child: Text(
                          (user['full_name'] ?? 'U')[0].toString().toUpperCase(),
                        ),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown'),
                      subtitle: Text(user['email']),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeUserFromBranch(user['id'], branch['id']),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _showAssignUserDialog(branch['id']),
            child: const Text('Assign User'),
          ),
        ],
      ),
    );
  }

  void _showAssignUserDialog(int branchId) async {
    // TODO: Implement user selection dialog
    _showInfoSnackBar('User assignment feature coming soon');
  }

  void _removeUserFromBranch(int userId, int branchId) async {
    try {
      await _branchService.removeUserFromBranch(
        userId: userId,
        branchId: branchId,
      );
      _showSuccessSnackBar('User removed from branch');
      _loadBranches();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _selectBranch(int branchId) async {
    try {
      final success = await _branchService.selectBranch(branchId);
      if (success) {
        _showSuccessSnackBar('Branch selected successfully');
        _loadBranches();
      } else {
        _showErrorSnackBar('Failed to select branch');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _confirmDeleteBranch(dynamic branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete ${branch['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _branchService.deleteBranch(branch['id']);
                Navigator.pop(context);
                _loadBranches();
                _showSuccessSnackBar('Branch deleted successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }
}
