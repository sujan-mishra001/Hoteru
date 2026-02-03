import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/organization_service.dart';

class OrganizationManagementScreen extends StatefulWidget {
  const OrganizationManagementScreen({super.key});

  @override
  State<OrganizationManagementScreen> createState() => _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState extends State<OrganizationManagementScreen> {
  final OrganizationService _orgService = OrganizationService();
  
  List<dynamic> _organizations = [];
  bool _isLoading = true;
  Map<String, dynamic>? _myOrg;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _myOrg = await _orgService.getMyOrganization();
    _organizations = await _orgService.getOrganizations();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Organization Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : CustomScrollView(
              slivers: [
                if (_myOrg != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "My Organization",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          _buildOrgCard(_myOrg!, isHero: true),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "All Organizations",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        TextButton.icon(
                          onPressed: _showAddOrgDialog,
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFFFFC107)),
                          label: const Text("New", style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                _organizations.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business_rounded, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text('No other organizations found', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final org = _organizations[index];
                              // Skip my org if it's already shown
                              if (_myOrg != null && org['id'] == _myOrg!['id']) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildOrgCard(org),
                              );
                            },
                            childCount: _organizations.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildOrgCard(Map<String, dynamic> org, {bool isHero = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHero ? const Color(0xFFFFC107).withOpacity(0.5) : Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isHero ? const Color(0xFFFFC107) : Colors.blueGrey).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_rounded, 
                color: isHero ? const Color(0xFFFFC107) : Colors.blueGrey,
              ),
            ),
            title: Text(
              org['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Slug: ${org['slug'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (org['address'] != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(org['address'], style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                    ],
                  ),
                ],
              ],
            ),
            trailing: isHero 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("OWNER", style: TextStyle(color: Color(0xFFFFC107), fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, org),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'validate', child: Text('Validate Subscription')),
                      const PopupMenuItem(value: 'delete', child: Text('Deactivate')),
                    ],
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  ),
          ),
          if (org['phone'] != null || org['email'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  if (org['phone'] != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(org['phone'], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                  if (org['email'] != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.email_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(org['email'], style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleAction(String action, dynamic org) {
    if (action == 'edit') {
      _showEditOrgDialog(org);
    } else if (action == 'delete') {
      _confirmDelete(org);
    } else if (action == 'validate') {
      _validateSub(org['id']);
    }
  }

  void _validateSub(int id) async {
    final result = await _orgService.getValidation(id);
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Subscription Validation"),
          content: Text(result?.toString() ?? "No validation data available"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        ),
      );
    }
  }

  void _showAddOrgDialog() {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Organization'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. My Restaurant Group'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(labelText: 'Slug', hintText: 'e.g. my-restaurant'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _orgService.createOrganization(
                  name: nameController.text,
                  slug: slugController.text,
                  address: addressController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                );
                Navigator.pop(context);
                _loadData();
                _showSuccess('Organization created successfully');
              } catch (e) {
                _showError(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditOrgDialog(dynamic org) {
    final nameController = TextEditingController(text: org['name']);
    final addressController = TextEditingController(text: org['address']);
    final phoneController = TextEditingController(text: org['phone']);
    final emailController = TextEditingController(text: org['email']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Organization'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await _orgService.updateOrganization(org['id'], {
                'name': nameController.text,
                'address': addressController.text,
                'phone': phoneController.text,
                'email': emailController.text,
              });
              if (success) {
                Navigator.pop(context);
                _loadData();
                _showSuccess('Organization updated');
              } else {
                _showError('Failed to update');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic org) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Organization'),
        content: Text('Are you sure you want to deactivate ${org['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await _orgService.deleteOrganization(org['id']);
              if (success) {
                Navigator.pop(context);
                _loadData();
                _showSuccess('Organization deactivated');
              } else {
                _showError('Failed to deactivate');
              }
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
}
