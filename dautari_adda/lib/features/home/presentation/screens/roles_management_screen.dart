import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/roles_service.dart';

class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen> {
  final RolesService _rolesService = RolesService();
  
  List<dynamic> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    _roles = await _rolesService.getRoles();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Roles & Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRoles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _roles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No roles found', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    return _buildRoleCard(role);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoleDialog,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add_rounded, color: Colors.black87),
      ),
    );
  }

  Widget _buildRoleCard(dynamic role) {
    final permissions = role['permissions'] as List? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.security_rounded, color: Color(0xFFFFC107), size: 20),
        ),
        title: Text(
          role['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          role['description'] ?? 'No description',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: () => _showEditRoleDialog(role),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(role),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text("Permissions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: permissions.map((p) => Chip(
                    label: Text(p.toString(), style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final availablePermissions = await _rolesService.getAvailablePermissions();
    List<String> selectedPermissions = [];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Role'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                const Text("Select Permissions", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...availablePermissions.map((p) => CheckboxListTile(
                  title: Text(p, style: const TextStyle(fontSize: 14)),
                  value: selectedPermissions.contains(p),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) selectedPermissions.add(p);
                      else selectedPermissions.remove(p);
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _rolesService.createRole(
                    name: nameController.text,
                    description: descController.text,
                    permissions: selectedPermissions,
                  );
                  Navigator.pop(context);
                  _loadRoles();
                } catch (e) {
                  _showError(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(dynamic role) async {
    final nameController = TextEditingController(text: role['name']);
    final descController = TextEditingController(text: role['description']);
    final availablePermissions = await _rolesService.getAvailablePermissions();
    List<String> selectedPermissions = List<String>.from(role['permissions'] ?? []);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Role'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                const Text("Select Permissions", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...availablePermissions.map((p) => CheckboxListTile(
                  title: Text(p, style: const TextStyle(fontSize: 14)),
                  value: selectedPermissions.contains(p),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) selectedPermissions.add(p);
                      else selectedPermissions.remove(p);
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await _rolesService.updateRole(role['id'], {
                  'name': nameController.text,
                  'description': descController.text,
                  'permissions': selectedPermissions,
                });
                if (success) {
                  Navigator.pop(context);
                  _loadRoles();
                } else {
                  _showError('Failed to update');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(dynamic role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete ${role['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await _rolesService.deleteRole(role['id']);
              if (success) {
                Navigator.pop(context);
                _loadRoles();
              } else {
                _showError('Failed to delete');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
}
