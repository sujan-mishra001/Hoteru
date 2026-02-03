import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'expenses_screen.dart';
import 'qr_management_screen.dart';
import 'profile_screen.dart';
import 'menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    // Default navigation items
    _navigationItems = [
      _getNavigationItemById('home'),
      _getNavigationItemById('orders'),
      _getNavigationItemById('profile'),
    ];
    _loadNavigationPreferences();
  }

  Future<void> _loadNavigationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList('navigation_items');
    
    if (savedItems != null && savedItems.isNotEmpty) {
      _applyNavigationItems(savedItems);
    } else {
      _applyNavigationItems(['home', 'orders', 'profile']);
    }
  }

  void _applyNavigationItems(List<String> ids) {
    final navMetadata = ids.map((id) => {
      'label': _getStaticItemLabel(id),
      'icon': _getStaticItemIcon(id),
    }).toList();

    setState(() {
      _navigationItems = ids.map((id) => _getNavigationItemById(id, navMetadata)).toList();
    });
  }

  NavigationItem _getNavigationItemById(String id, [List<Map<String, dynamic>>? navMetadata]) {
    final allItems = {
      'home': NavigationItem(
        id: 'home',
        label: 'Home',
        icon: Icons.home_rounded,
        screen: HomeScreen(
          onSettingsTap: _showNavigationSettings,
          onTabChange: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          navigationItems: navMetadata,
        ),
      ),
      'menu': NavigationItem(
        id: 'menu',
        label: 'Menu',
        icon: Icons.restaurant_menu_rounded,
        screen: MenuScreen(tableNumber: 1, isOrderingMode: false), // Default to table 1 or a global view
      ),
      'orders': NavigationItem(
        id: 'orders',
        label: 'Orders',
        icon: Icons.shopping_bag_rounded,
        screen: const OrdersScreen(),
      ),
      'expenses': NavigationItem(
        id: 'expenses',
        label: 'Expenses',
        icon: Icons.receipt_long_rounded,
        screen: const ExpensesScreen(),
      ),
      'qr': NavigationItem(
        id: 'qr',
        label: 'QR Codes',
        icon: Icons.qr_code_2_rounded,
        screen: const QrManagementScreen(),
      ),
      'profile': NavigationItem(
        id: 'profile',
        label: 'Profile',
        icon: Icons.person_rounded,
        screen: const ProfileScreen(),
      ),
    };
    
    return allItems[id] ?? allItems['home']!;
  }

  Future<void> _showNavigationSettings() async {
    final allAvailableItems = [
      'home',
      'menu',
      'orders',
      'expenses',
      'qr',
      'profile',
    ];

    final selectedItems = await showDialog<List<String>>(
      context: context,
      builder: (context) => _NavigationSettingsDialog(
        currentItems: _navigationItems.map((e) => e.id).toList(),
        availableItems: allAvailableItems,
      ),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('navigation_items', selectedItems);
      
      _applyNavigationItems(selectedItems);
      
      if (_currentIndex >= _navigationItems.length) {
        setState(() {
          _currentIndex = 0;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Navigation updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _navigationItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;
              
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? Colors.black87 : Colors.white60,
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.small(
          onPressed: _showNavigationSettings,
          backgroundColor: Colors.white,
          elevation: 2,
          child: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 18),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final Widget screen;

  NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.screen,
  });
}

class _NavigationSettingsDialog extends StatefulWidget {
  final List<String> currentItems;
  final List<String> availableItems;

  const _NavigationSettingsDialog({
    required this.currentItems,
    required this.availableItems,
  });

  @override
  State<_NavigationSettingsDialog> createState() => _NavigationSettingsDialogState();
}

class _NavigationSettingsDialogState extends State<_NavigationSettingsDialog> {
  late List<String> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.currentItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Customize Navigation'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select 3-5 items for bottom navigation:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...widget.availableItems.map((id) {
              final isSelected = selectedItems.contains(id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      if (selectedItems.length < 5) {
                        selectedItems.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maximum 5 items allowed'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } else {
                      if (selectedItems.length > 3) {
                        selectedItems.remove(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Minimum 3 items required'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  });
                },
                title: Row(
                  children: [
                    Icon(_getStaticItemIcon(id), size: 20),
                    const SizedBox(width: 12),
                    Text(_getStaticItemLabel(id)),
                  ],
                ),
                activeColor: const Color(0xFFFFC107),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedItems.length >= 3
              ? () => Navigator.pop(context, selectedItems)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black87,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _getStaticItemLabel(String id) {
  final labels = {
    'home': 'Home',
    'menu': 'Menu',
    'orders': 'Orders',
    'expenses': 'Expenses',
    'qr': 'QR Codes',
    'profile': 'Profile',
  };
  return labels[id] ?? id;
}

IconData _getStaticItemIcon(String id) {
  final icons = {
    'home': Icons.home_rounded,
    'menu': Icons.restaurant_menu_rounded,
    'orders': Icons.shopping_bag_rounded,
    'expenses': Icons.receipt_long_rounded,
    'qr': Icons.qr_code_2_rounded,
    'profile': Icons.person_rounded,
  };
  return icons[id] ?? Icons.help_outline_rounded;
}
