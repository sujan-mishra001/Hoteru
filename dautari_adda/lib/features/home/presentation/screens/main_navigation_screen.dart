import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/features/auth/presentation/screens/branch_selection_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/orders_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/kot_management_screen.dart';
import 'package:dautari_adda/features/analytics/presentation/screens/reports_screen.dart';
import 'package:dautari_adda/features/profile/presentation/screens/profile_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/cashier_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late List<NavigationItem> _navigationItems;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Default navigation items in the requested order
    _navigationItems = [
      _getNavigationItemById('home'),
      _getNavigationItemById('orders'),
      _getNavigationItemById('kot'),
      _getNavigationItemById('cashier'),
      _getNavigationItemById('reports'),
    ];
    _loadNavigationPreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadNavigationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList('navigation_items');
    
    if (savedItems != null && savedItems.isNotEmpty) {
      _applyNavigationItems(savedItems);
    } else {
      // Default order: Home, Orders, KOT/BOT, Cashier, Reports, Profile
      _applyNavigationItems(['home', 'orders', 'kot', 'cashier', 'reports', 'profile']);
    }
  }

  void _applyNavigationItems(List<String> ids) {
    // Define the strict order
    final orderedIds = ['home', 'orders', 'kot', 'cashier', 'reports', 'profile'];
    
    // Sort the incoming ids based on their index in orderedIds
    final sortedIds = ids.where((id) => orderedIds.contains(id)).toList()
      ..sort((a, b) => orderedIds.indexOf(a).compareTo(orderedIds.indexOf(b)));

    final navMetadata = sortedIds.map((id) => {
      'id': id,
      'label': _getStaticItemLabel(id),
      'icon': _getStaticItemIcon(id),
    }).toList();

    setState(() {
      _navigationItems = sortedIds.map((id) => _getNavigationItemById(id, navMetadata)).toList();
      // Update PageController if current index is out of bounds
      if (_currentIndex >= _navigationItems.length) {
        _currentIndex = 0;
        _pageController.jumpToPage(0);
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  NavigationItem _getNavigationItemById(String id, [List<Map<String, dynamic>>? navMetadata]) {
    final onTabChange = (int index) {
      _onNavItemTapped(index);
    };

    final Map<String, NavigationItem> allItems = {
      'home': NavigationItem(
        id: 'home',
        label: 'Home',
        icon: Icons.home_rounded,
        screen: HomeScreen(
          onSettingsTap: _showNavigationSettings,
          onTabChange: onTabChange,
          navigationItems: navMetadata,
        ),
      ),
      'orders': NavigationItem(
        id: 'orders',
        label: 'Orders',
        icon: Icons.shopping_bag_rounded,
        screen: OrdersScreen(
          navigationItems: navMetadata,
          onTabChange: onTabChange,
        ),
      ),
      'kot': NavigationItem(
        id: 'kot',
        label: 'KOT/BOT',
        icon: Icons.kitchen_rounded,
        screen: KotManagementScreen(navigationItems: navMetadata),
      ),
      'reports': NavigationItem(
        id: 'reports',
        label: 'Reports',
        icon: Icons.analytics_rounded,
        screen: ReportsScreen(navigationItems: navMetadata),
      ),
      'profile': NavigationItem(
        id: 'profile',
        label: 'Profile',
        icon: Icons.person_rounded,
        screen: ProfileScreen(navigationItems: navMetadata),
      ),
      'cashier': NavigationItem(
        id: 'cashier',
        label: 'Cashier',
        icon: Icons.payments_rounded,
        screen: CashierScreen(
          navigationItems: navMetadata,
          onTabChange: onTabChange,
        ),
      ),
    };
    
    return allItems[id] ?? allItems['home']!;
  }

  Future<void> _showNavigationSettings() async {
    final allAvailableItems = [
      'home',
      'orders',
      'kot',
      'cashier',
      'reports',
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
    return WillPopScope(
      onWillPop: () async {
        // Navigate to branch selection screen instead of closing the app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _navigationItems.map((item) => item.screen).toList(),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFFFC107),
            unselectedItemColor: Colors.grey[400],
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: _navigationItems.map((item) {
              return BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              );
            }).toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: _showNavigationSettings,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.tune_rounded, color: Colors.grey, size: 20),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
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
  final List<String> _orderedAvailableItems = const ['home', 'orders', 'kot', 'cashier', 'reports', 'profile'];

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
              'Select 3-6 items for bottom navigation:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe left/right to navigate between selected items',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ..._orderedAvailableItems.map((id) {
              final isSelected = selectedItems.contains(id);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFC107) : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? const Color(0xFFFFC107).withOpacity(0.1) : null,
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (selectedItems.length < 6) {
                          selectedItems.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Maximum 6 items allowed'),
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
                ),
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
    'orders': 'Orders',
    'kot': 'KOT/BOT',
    'reports': 'Reports',
    'profile': 'Profile',
    'cashier': 'Cashier',
  };
  return labels[id] ?? id;
}

IconData _getStaticItemIcon(String id) {
  final icons = {
    'home': Icons.home_rounded,
    'orders': Icons.shopping_bag_rounded,
    'kot': Icons.kitchen_rounded,
    'reports': Icons.analytics_rounded,
    'profile': Icons.person_rounded,
    'cashier': Icons.payments_rounded,
  };
  return icons[id] ?? Icons.help_outline_rounded;
}
