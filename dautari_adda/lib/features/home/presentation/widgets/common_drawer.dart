import 'package:flutter/material.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import '../screens/expenses_screen.dart';
import '../screens/profile_screen.dart'; 
import '../screens/home_screen.dart';
import '../screens/qr_management_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/users_management_screen.dart';
import '../screens/session_control_screen.dart';
import '../screens/branch_management_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/purchase_management_screen.dart';
import '../screens/delivery_partners_screen.dart';
import '../screens/floors_tables_management_screen.dart';
import '../screens/settings_screen.dart';

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
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 24, color: Color(0xFFFFC107)),
                  ),
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
            leading: const Icon(Icons.shopping_bag),
            title: const Text("Orders"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
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
            leading: const Icon(Icons.receipt_long),
            title: const Text("My Expenses / Bills"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpensesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text("QR Codes Management"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const QrManagementScreen()));
            },
          ),
          const Divider(),
          // Management Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text("Menu & Categories"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuScreen()));
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
