import 'package:flutter/material.dart';
import 'inventory_products_screen.dart';
import 'units_management_screen.dart';
import 'stock_management_screen.dart';
import 'counts_screen.dart';
import 'bom_management_screen.dart';
// import 'production_screen.dart';
// import 'production_count_screen.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventory Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuTile(
            context,
            icon: Icons.inventory_2_rounded,
            title: 'Products',
            subtitle: 'Manage raw materials and inventory items',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryProductsScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.straighten_rounded,
            title: 'Units',
            subtitle: 'Manage units of measurement',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitsManagementScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.swap_horiz_rounded,
            title: 'Stock Management',
            subtitle: 'Track stock ins, outs and adjustments',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StockManagementScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.fact_check_rounded,
            title: 'Counts',
            subtitle: 'Physical stock counting and reconciliation',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CountsScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.list_alt_rounded,
            title: 'BOM (Bill of Materials)',
            subtitle: 'Define recipes and material requirements',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BOMManagementScreen())),
          ),
          _buildMenuTile(
            context,
            icon: Icons.precision_manufacturing_rounded,
            title: 'Production',
            subtitle: 'Record batch production and consumption',
            onTap: () => _showPlaceholder(context, 'Production'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.bar_chart_rounded,
            title: 'Production Count',
            subtitle: 'View production history and summaries',
            onTap: () => _showPlaceholder(context, 'Production Count'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFC107), size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title screen is coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }
}
