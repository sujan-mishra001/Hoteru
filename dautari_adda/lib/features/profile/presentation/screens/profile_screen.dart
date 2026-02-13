import 'package:flutter/material.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/features/auth/presentation/screens/login_screen.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import 'package:dautari_adda/core/theme/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';

// Management Screens
// Management Screens
import 'package:dautari_adda/features/admin/presentation/screens/branch_management_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/company_data_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/users_management_screen.dart';
import 'package:dautari_adda/features/customers/presentation/screens/customers_management_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/roles_management_screen.dart';
import 'package:dautari_adda/features/inventory/presentation/screens/inventory_management_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/kot_management_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/session_control_screen.dart';
import 'package:dautari_adda/features/analytics/presentation/screens/reports_screen.dart';
import 'settings_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_management_screen.dart' as dautari_adda_menu;
import 'package:dautari_adda/features/inventory/presentation/screens/purchase_management_screen.dart';
import 'package:dautari_adda/features/inventory/presentation/screens/delivery_partners_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/floors_tables_management_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/qr_management_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/printer_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? navigationItems;
  const ProfileScreen({super.key, this.navigationItems});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  String? _branchName;
  bool _isLoading = true;
  bool _isCompanyLoading = true;
  bool _isUploading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      final response = await _apiService.get('/settings/company');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _companyData = Map<String, dynamic>.from(data);
            _isCompanyLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isCompanyLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading company data: $e');
      if (mounted) {
        setState(() => _isCompanyLoading = false);
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService().getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });

      // Fetch branch name
      if (profile != null && profile['current_branch_id'] != null) {
        try {
          final branches = await AuthService().getUserBranches();
          final currentBranch = branches.firstWhere(
            (b) => b['id'] == profile['current_branch_id'],
            orElse: () => null,
          );
          if (currentBranch != null) {
            setState(() => _branchName = currentBranch['name']);
          }
        } catch (e) {
          debugPrint("Error fetching branch name: $e");
        }
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    // Show options: Camera or Gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFFC107)),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFFC107)),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload to backend
      final success = await AuthService().uploadProfilePicture(File(image.path));

      if (success) {
        // Reload profile to get new image URL
        await _loadUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                "Logout",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to sign out? You will need to login again to access the dashboard.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout != true) return;

    final prefs = await SharedPreferences.getInstance();
    await AuthService().logout();
    await prefs.setBool('isLoggedIn', false);

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))));
    }

    final name = _userProfile?['full_name'] ?? _userProfile?['username'] ?? "User";
    final email = _userProfile?['email'] ?? "Dautari Adda Staff";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Redesigned
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _uploadProfilePicture,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                            backgroundImage: () {
                              final imageUrl = _userProfile?['profile_image_url'];
                              if (imageUrl == null || imageUrl == "") return null;
                              
                              final fullUrl = imageUrl.toString().startsWith('http') 
                                  ? imageUrl.toString() 
                                  : '${ApiService.baseHostUrl}${imageUrl.toString().startsWith('/') ? '' : '/'}$imageUrl';
                                  
                              return NetworkImage(fullUrl);
                            }(),
                            child: _isUploading
                                ? const CircularProgressIndicator(color: Color(0xFFFFC107))
                                : (_userProfile?['profile_image_url'] == null || _userProfile?['profile_image_url'] == "")
                                    ? const Icon(Icons.person, size: 50, color: Color(0xFFFFC107))
                                    : null,
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading profile picture: $exception');
                            },
                          ),
                        ),
                        // Camera icon badge
                        if (!_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 90),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            if (_branchName != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFFFFC107)),
                  const SizedBox(width: 4),
                  Text(
                    _branchName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Management Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Administration",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.location_city_rounded,
                    title: 'Branches',
                    subtitle: _branchName != null ? 'Current: $_branchName' : 'Manage your restaurant branches',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BranchManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.business_rounded,
                    title: 'Company Data',
                    subtitle: 'View company profile and settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyDataScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Menu Management',
                    subtitle: 'Manage categories and items',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const dautari_adda_menu.MenuManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.people_alt_rounded,
                    title: 'Staff Management',
                    subtitle: 'Manage users and system roles',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.security_rounded,
                    title: 'Roles & Permissions',
                    subtitle: 'Define access control levels',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RolesManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.table_restaurant_rounded,
                    title: 'Floors & Tables',
                    subtitle: 'Layout and table configuration',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FloorsTablesManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.person_search_rounded,
                    title: 'Customers',
                    subtitle: 'Manage customer database',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.qr_code_rounded,
                    title: 'QR Code Management',
                    subtitle: 'Manage digital menu & payment QRs',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrManagementScreen())),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Operations",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory',
                    subtitle: 'Track stock and materials',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.analytics_rounded,
                    title: 'Reports & Analytics',
                    subtitle: 'View reports and analytics',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.shopping_cart_rounded,
                    title: 'Purchases',
                    subtitle: 'Manage supplier bills and returns',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseManagementScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.delivery_dining_rounded,
                    title: 'Delivery Partners',
                    subtitle: 'Manage external delivery services',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryPartnersScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.timer_rounded,
                    title: 'Staff Sessions',
                    subtitle: 'Manage duty shifts and sessions',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SessionControlScreen())),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "System",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'General application preferences',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                  ),
                  const SizedBox(height: 32),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Securely sign out from your account',
                    onTap: () => _logout(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
    final companyName = _companyData?['company_name'] ?? 'Not configured';
    final companyEmail = _companyData?['email'] ?? '-';
    final companyPhone = _companyData?['phone'] ?? '-';
    final companyAddress = _companyData?['address'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFC107).withOpacity(0.15),
            const Color(0xFFFFD54F).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Color(0xFFFFC107), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      companyName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Color(0xFFFFC107)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CompanyDataScreen()),
                ).then((_) => _loadCompanyData()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: const Color(0xFFFFC107).withOpacity(0.2), height: 1),
          const SizedBox(height: 16),
          _buildCompanyDetailRow(Icons.email, companyEmail),
          const SizedBox(height: 8),
          _buildCompanyDetailRow(Icons.phone, companyPhone),
          const SizedBox(height: 8),
          _buildCompanyDetailRow(Icons.location_on, companyAddress),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(ThemeProvider().isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFFFFC107).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFFFFC107),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
