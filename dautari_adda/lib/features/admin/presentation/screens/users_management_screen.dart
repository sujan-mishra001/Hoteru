import 'package:flutter/material.dart';
import 'package:dautari_adda/features/admin/data/user_service.dart';
import 'package:dautari_adda/features/admin/data/roles_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final UserService _userService = UserService();
  final RolesService _rolesService = RolesService();
  
  List<dynamic> _users = [];
  List<dynamic> _roles = [];
  bool _isLoading = true;
  bool _isAdmin = true; // TODO: Get from auth service

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final usersFuture = _userService.getUsers();
    final rolesFuture = _rolesService.getRoles();
    
    final results = await Future.wait([usersFuture, rolesFuture]);
    setState(() {
      _users = results[0] as List<dynamic>;
      _roles = results[1] as List<dynamic>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFFFFC107),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddUserDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No users found'),
                      if (_isAdmin)
                        ElevatedButton(
                          onPressed: () => _showAddUserDialog(),
                          child: const Text('Add First User'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserCard(user);
                  },
                ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFC107),
          child: Text(
            (user['full_name'] ?? 'U')[0].toString().toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user['full_name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? ''),
            const SizedBox(height: 4),
            _buildRoleChip(user['role']),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user['disabled'] == true)
              const Icon(Icons.block, color: Colors.red),
            if (_isAdmin)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit User'),
                  ),
                  const PopupMenuItem(
                    value: 'disable',
                    child: Text('Disable User'),
                  ),
                  const PopupMenuItem(
                    value: 'enable',
                    child: Text('Enable User'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete User'),
                  ),
                ],
              ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Widget _buildRoleChip(String? role) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.red[100]!;
        break;
      case 'manager':
        color = Colors.blue[100]!;
        break;
      case 'staff':
        color = Colors.green[100]!;
        break;
      default:
        color = Colors.grey[100]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role?.toUpperCase() ?? 'UNKNOWN',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleMenuAction(String action, dynamic user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'disable':
        _toggleUserStatus(user['id'], true);
        break;
      case 'enable':
        _toggleUserStatus(user['id'], false);
        break;
      case 'delete':
        _confirmDeleteUser(user);
        break;
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'staff';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles.map<DropdownMenuItem<String>>((role) {
                  return DropdownMenuItem<String>(
                    value: role['name'] as String,
                    child: Text(role['name']),
                  );
                }).toList(),
                onChanged: (value) => selectedRole = value!,
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
                await _userService.createUser(
                  email: emailController.text,
                  password: passwordController.text,
                  fullName: nameController.text,
                  role: selectedRole,
                );
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('User created successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(dynamic user) {
    final nameController = TextEditingController(text: user['full_name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles.map<DropdownMenuItem<String>>((role) {
                  return DropdownMenuItem<String>(
                    value: role['name'] as String,
                    child: Text(role['name']),
                  );
                }).toList(),
                onChanged: (value) => selectedRole = value!,
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
                await _userService.updateUser(user['id'], {
                  'full_name': nameController.text,
                  'email': emailController.text,
                  'role': selectedRole,
                });
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('User updated successfully');
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

  void _toggleUserStatus(int userId, bool disabled) async {
    try {
      await _userService.disableUser(userId, disabled);
      _loadData();
      _showSuccessSnackBar(
        disabled ? 'User disabled successfully' : 'User enabled successfully',
      );
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _confirmDeleteUser(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _userService.deleteUser(user['id']);
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('User deleted successfully');
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

  void _showUserDetails(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['full_name'] ?? 'User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user['email'] ?? ''),
            _buildDetailRow('Role', user['role'] ?? ''),
            _buildDetailRow('Status', user['disabled'] == true ? 'Disabled' : 'Active'),
            _buildDetailRow('Created At', user['created_at'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
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
}
