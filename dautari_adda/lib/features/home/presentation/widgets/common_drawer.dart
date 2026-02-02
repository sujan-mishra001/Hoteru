import 'package:flutter/material.dart';
import 'package:dautari_adda/features/auth/data/auth_service.dart';
import '../screens/expenses_screen.dart';
import '../screens/profile_screen.dart'; 
import '../screens/home_screen.dart';
import '../screens/qr_management_screen.dart';
import '../screens/orders_screen.dart';

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
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement settings
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings coming soon")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.more_horiz),
            title: const Text("More Features"),
            onTap: () {
               Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("More features coming soon")));
            },
          ),
        ],
      ),
    );
  }
}
