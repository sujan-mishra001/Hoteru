import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import 'package:dautari_adda/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';

class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({super.key});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _branches = [];
  bool _isLoading = true;
  int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    try {
      final branches = await _authService.getUserBranches();
      setState(() {
        _branches = branches;
        _isLoading = false;
        if (_branches.length == 1) {
          _selectedBranchId = _branches[0]['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ToastService.show(context, "Failed to load branches", isError: true);
    }
  }

  Future<void> _handleBranchSelect(int branchId) async {
    setState(() => _selectedBranchId = branchId);
    try {
      final success = await _authService.switchBranch(branchId);
      if (success && mounted) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Branch',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            onPressed: () async {
              await _authService.logout();
              if (mounted) Navigator.of(context).pop();
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
                        'Welcome Back!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please select a branch to continue to the POS system.',
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
        color: isSelected ? const Color(0xFFFFF8E1) : Colors.white,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No branches assigned',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You are not associated with any branch yet. Please contact your administrator.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}