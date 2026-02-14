import 'package:flutter/material.dart';
import 'package:dautari_adda/features/admin/data/branch_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(screenHeight),
                _branches.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final branch = _branches[index];
                              return _buildBranchCard(branch);
                            },
                            childCount: _branches.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(double screenHeight) {
    return SliverAppBar(
      expandedHeight: screenHeight / 3, // Modern requirement: 1/3 of the page
      pinned: true,
      backgroundColor: const Color(0xFFFFC107),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
          onPressed: _loadBranches,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Icon(Icons.location_city_rounded, size: 220, color: Colors.white.withOpacity(0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Branch\nLocations",
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Currently managing ${_branches.length} branches",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8FB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text(
            'No branches found',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isAdmin)
            ElevatedButton.icon(
              onPressed: () => _showAddBranchDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Branch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(dynamic branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFFE6A700), size: 24),
              ),
              title: Text(
                branch['name'] ?? 'Unknown Branch',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[900]),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Code: ${branch['code'] ?? 'N/A'}', style: GoogleFonts.outfit(color: Colors.blueGrey[400], fontSize: 13)),
              ),
              trailing: _isAdmin
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, branch),
                    icon: Icon(Icons.more_vert_rounded, color: Colors.blueGrey[400]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'users', child: Row(children: [Icon(Icons.people_alt_rounded, size: 18), SizedBox(width: 8), Text('Staff')])),
                      const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.check_circle_rounded, size: 18), SizedBox(width: 8), Text('Select')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () => _selectBranch(branch['id']),
                  ),
            ),
            if (branch['address'] != null || branch['phone'] != null) ...[
              const Divider(height: 1, indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (branch['address'] != null)
                      _buildInfoRow(Icons.map_rounded, branch['address']),
                    if (branch['phone'] != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.phone_rounded, branch['phone']),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey[300]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(color: Colors.blueGrey[600], fontSize: 14),
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
      case 'select':
        _selectBranch(branch['id']);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name', prefixIcon: Icon(Icons.business_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Branch Code', prefixIcon: Icon(Icons.tag_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch Name', prefixIcon: Icon(Icons.business_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        title: Text('Users in ${branch['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: users.isEmpty
              ? const Center(child: Text('No users assigned to this branch'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFFC107).withOpacity(0.2),
                        foregroundColor: const Color(0xFFE6A700),
                        child: Text(
                          (user['full_name'] ?? 'U')[0].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text(user['email'], style: GoogleFonts.outfit(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
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
            style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFFFFC107),
               foregroundColor: Colors.black87,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Assign User'),
          ),
        ],
      ),
    );
  }

  void _showAssignUserDialog(int branchId) async {
    _showInfoSnackBar('User assignment feature coming soon');
  }

  void _removeUserFromBranch(int userId, int branchId) async {
    try {
      await _branchService.removeUserFromBranch(
        userId: userId,
        branchId: branchId,
      );
      _showSuccessSnackBar('User removed from branch');
      Navigator.pop(context); // Close dialog
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
        content: Text('Are you sure you want to delete ${branch['name']}? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
