import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import 'package:dautari_adda/features/admin/data/branch_service.dart';
import 'package:dautari_adda/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:dautari_adda/features/auth/presentation/screens/login_screen.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  final AuthService _authService = AuthService();
  final BranchService _branchService = BranchService();
  List<dynamic> _branches = [];
  bool _isLoading = true;
  int? _selectedBranchId;
  String _userRole = 'user';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadUserProfile();
    await _loadBranches();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userRole = profile['role'] ?? 'user';
          _isAdmin = _userRole.toLowerCase() == 'admin';
        });
      } else {
        // If profile is null, it likely means the token is invalid
        _handleLogout();
      }
    } catch (e) {
      print('DEBUG: Profile load error: $e');
      if (mounted) ToastService.show(context, "Error loading user profile", isError: true);
    }
  }

  void _handleLogout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> _loadBranches() async {
    try {
      // Use getBranches() for admins to see all, or getMyBranches() for specific assignments
      final branches = _isAdmin 
          ? await _branchService.getBranches() 
          : await _branchService.getMyBranches();
      
      setState(() {
        _branches = branches;
        if (_branches.isNotEmpty && _branches.length == 1) {
          _selectedBranchId = _branches[0]['id'];
        }
      });
    } catch (e) {
      if (mounted) ToastService.show(context, "Failed to load branches", isError: true);
    }
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Branch', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Branch Name',
                hintText: 'e.g. Dautari Adda - Baneshwor',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Branch Code',
                hintText: 'e.g. BSN-01',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Location/Address',
                hintText: 'e.g. Kathmandu, Nepal',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || codeController.text.isEmpty) {
                ToastService.show(context, "Name and Code are required", isError: true);
                return;
              }
              try {
                await _branchService.createBranch(
                  name: nameController.text,
                  code: codeController.text,
                  location: addressController.text,
                );
                Navigator.pop(context);
                _loadBranches();
                ToastService.show(context, "Branch created successfully");
              } catch (e) {
                ToastService.show(context, e.toString(), isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Create', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBranchSelect(int branchId) async {
    setState(() => _selectedBranchId = branchId);
    try {
      final success = await _authService.switchBranch(branchId);
      if (success && mounted) {
        // Essential: Update the TableService singleton with the new branch ID
        // so it uses the correct filtering for subsequent API calls.
        await TableService().setBranchId(branchId);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        if (mounted) ToastService.show(context, "Failed to select branch", isError: true);
      }
    } catch (e) {
      if (mounted) ToastService.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Branch',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_business_rounded, color: Colors.black87),
              tooltip: 'Add Branch',
              onPressed: _showAddBranchDialog,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            onPressed: () async {
              await _authService.logout();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAdmin ? 'Organization Admin' : 'Welcome Staff!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isAdmin 
                          ? 'Manage your branches or select one to enter the dashboard.'
                          : 'Please select your assigned branch to continue.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _branches.isEmpty
                      ? _buildNoBranchesView()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            final branch = _branches[index];
                            final isSelected = _selectedBranchId == branch['id'];
                            return _buildBranchCard(branch, isSelected);
                          },
                        ),
                ),
                if (_selectedBranchId != null && _branches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleBranchSelect(_selectedBranchId!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: Text(
                          'Enter Selected Branch',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildBranchCard(dynamic branch, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFFFC107).withOpacity(0.1) 
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedBranchId = branch['id']),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront_rounded, color: Color(0xFFFFC107)),
        ),
        title: Text(
          branch['name'] ?? 'Unknown Branch',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${branch['code']}', style: GoogleFonts.poppins(fontSize: 12)),
            if (branch['location'] != null)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(branch['location'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFC107))
            : const Icon(Icons.circle_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildNoBranchesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              _isAdmin ? 'No Branches Created' : 'No Branches Assigned',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isAdmin 
                  ? 'Your organization needs at least one branch to start using the POS system.' 
                  : 'You are not associated with any branch yet. Please contact your administrator to get assigned.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            if (_isAdmin)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _showAddBranchDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Create First Branch', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}