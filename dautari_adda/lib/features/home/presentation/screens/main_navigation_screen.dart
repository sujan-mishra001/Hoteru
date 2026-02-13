import 'package:flutter/material.dart';
import 'package:dautari_adda/features/auth/presentation/screens/branch_selection_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/orders_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/kot_management_screen.dart';
import 'package:dautari_adda/features/profile/presentation/screens/profile_screen.dart';
import 'package:dautari_adda/features/pos/presentation/screens/cashier_screen.dart';
import 'package:dautari_adda/features/pos/data/floor_constants.dart';
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
  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _ordersNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _kotNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _cashierNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _navigationItems = [
      _getNavigationItemById('home'),
      _getNavigationItemById('orders'),
      _getNavigationItemById('kot'),
      _getNavigationItemById('cashier'),
      _getNavigationItemById('profile'),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    // If switching to Home tab, ensure Navigator shows HomeScreen
    if (index == 0) {
      final state = _homeNavKey.currentState;
      if (state != null && state.canPop()) {
        state.popUntil((route) => route.isFirst);
      }
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Map<String, dynamic>> _getNavItemsForChild() {
    return [
      {'id': 'home', 'label': 'Home', 'icon': Icons.home_rounded},
      {'id': 'orders', 'label': 'Orders', 'icon': Icons.shopping_bag_rounded},
      {'id': 'kot', 'label': 'KOT/BOT', 'icon': Icons.kitchen_rounded},
      {'id': 'cashier', 'label': 'Cashier', 'icon': Icons.payments_rounded},
      {'id': 'profile', 'label': 'Profile', 'icon': Icons.person_rounded},
    ];
  }

  void _handleBackPressed() {
    if (_currentIndex == 0) {
      final state = _homeNavKey.currentState;
      if (state != null && state.canPop()) {
        state.pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
        );
      }
    } else if (_currentIndex == 1) {
      final state = _ordersNavKey.currentState;
      if (state != null && state.canPop()) {
        state.pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
        );
      }
    } else if (_currentIndex == 2) {
      final state = _kotNavKey.currentState;
      if (state != null && state.canPop()) {
        state.pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
        );
      }
    } else if (_currentIndex == 3) {
      final state = _cashierNavKey.currentState;
      if (state != null && state.canPop()) {
        state.pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BranchSelectionScreen()),
      );
    }
  }

  NavigationItem _getNavigationItemById(String id) {
    final navItems = _getNavItemsForChild();
    final Map<String, NavigationItem> allItems = {
      'home': NavigationItem(
        id: 'home',
        label: 'Home',
        icon: Icons.home_rounded,
        screen: Navigator(
          key: _homeNavKey,
          onGenerateRoute: (settings) {
            // Always return HomeScreen regardless of route name
            return MaterialPageRoute(
              builder: (context) => HomeScreen(
                navigationItems: navItems,
                onTabChange: _onNavItemTapped,
              ),
            );
          },
        ),
      ),
      'orders': NavigationItem(
        id: 'orders',
        label: 'Orders',
        icon: Icons.shopping_bag_rounded,
        screen: Navigator(
          key: _ordersNavKey,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (context) => OrdersScreen(
              navigationItems: navItems,
              onTabChange: _onNavItemTapped,
            ),
          ),
        ),
      ),
      'kot': NavigationItem(
        id: 'kot',
        label: 'KOT/BOT',
        icon: Icons.kitchen_rounded,
        screen: Navigator(
          key: _kotNavKey,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (context) => KotManagementScreen(
              navigationItems: navItems,
              onTabChange: _onNavItemTapped,
            ),
          ),
        ),
      ),
      'cashier': NavigationItem(
        id: 'cashier',
        label: 'Cashier',
        icon: Icons.payments_rounded,
        screen: Navigator(
          key: _cashierNavKey,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (context) => CashierScreen(
              navigationItems: navItems,
              onTabChange: _onNavItemTapped,
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
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
            items: _navigationItems.map((item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            )).toList(),
          ),
        ),
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
