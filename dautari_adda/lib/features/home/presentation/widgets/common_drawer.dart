import 'package:flutter/material.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/orders_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/qr_management_screen.dart';
import 'package:dautari_adda/features/profile/presentation/screens/profile_screen.dart';
import 'package:dautari_adda/features/analytics/presentation/screens/reports_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/users_management_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/session_control_screen.dart';
import 'package:dautari_adda/features/admin/presentation/screens/branch_management_screen.dart';
import 'package:dautari_adda/features/inventory/presentation/screens/purchase_management_screen.dart';
import 'package:dautari_adda/features/inventory/presentation/screens/delivery_partners_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/floors_tables_management_screen.dart';
import 'package:dautari_adda/features/profile/presentation/screens/settings_screen.dart';
import 'package:dautari_adda/features/analytics/presentation/screens/dashboard_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/cashier_screen.dart';
import 'package:dautari_adda/features/analytics/presentation/screens/day_book_screen.dart';
import 'package:dautari_adda/features/analytics/presentation/screens/food_cost_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/kot_management_screen.dart';

import '../screens/home_screen.dart';
import '../screens/communications_screen.dart';

class CommonDrawer extends StatelessWidget {
  const CommonDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().getUserProfile(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final name = user?['full_name'] ?? "Staff Member";
              final email = user?['email'] ?? "staff@dautariadda.com";
              final initial = name.isNotEmpty ? name[0].toUpperCase() : "S";

              return UserAccountsDrawerHeader(
                accountName: Text(name),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: () {
                    final imageUrl = user?['profile_image_url'];
                    if (imageUrl == null || imageUrl == "") return null;
                    
                    final fullUrl = imageUrl.toString().startsWith('http') 
                        ? imageUrl.toString() 
                        : '${ApiService.baseHostUrl}${imageUrl.toString().startsWith('/') ? '' : '/'}$imageUrl';
                        
                    return NetworkImage(fullUrl);
                  }(),
                  child: (user?['profile_image_url'] == null || user?['profile_image_url'] == "")
                      ? Text(
                          initial,
                          style: const TextStyle(fontSize: 24, color: Color(0xFFFFC107)),
                        )
                      : null,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text("Orders"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text("Cashier"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CashierScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.kitchen),
            title: const Text("KOT / BOT"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KotManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text("Reports & Analytics"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text("Day Book"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DayBookScreen()));
            },
          ),
          const Divider(),
          // Management Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text("Food Cost Analysis"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodCostScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text("Communications"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunicationsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("User Management"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.branch),
            title: const Text("Branches"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BranchManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text("Session Control"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SessionControlScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text("Purchase & Suppliers"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text("Delivery Partners"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryPartnersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: const Text("Floors & Tables"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FloorsTablesManagementScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pop(context);
              AuthService().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
