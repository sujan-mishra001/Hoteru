import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/menu_service.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/order_overview_screen.dart';
import 'package:dautari_adda/core/api/api_service.dart';

class MenuScreen extends StatefulWidget {
  final int tableNumber;
  final List<Map<String, dynamic>>? navigationItems;
  final bool isOrderingMode;
  final String? orderType;
  final String? customerName;
  final int? deliveryPartnerId;

  const MenuScreen({
    super.key,
    required this.tableNumber,
    this.navigationItems,
    this.isOrderingMode = true,
    this.orderType,
    this.customerName,
    this.deliveryPartnerId,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  final TableService _tableService = TableService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<MenuCategory> _fullMenu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    // 1. Initial Load immediately
    final menu = await _menuService.getMenu();
    if (mounted) {
      setState(() {
        _fullMenu = menu;
        _isLoading = false;
      });
    }

    // 2. Poll for updates
    _menuService.getMenuStream().listen((data) {
      if (mounted) {
        setState(() {
          _fullMenu = data;
        });
      }
    });
  }

  List<MenuCategory> _getFilteredMenu() {
    if (_searchQuery.isEmpty) return _fullMenu;

    final List<MenuCategory> filtered = [];
    for (var category in _fullMenu) {
      final match = _filterCategory(category);
      if (match != null) {
        filtered.add(match);
      }
    }
    return filtered;
  }

  MenuCategory? _filterCategory(MenuCategory category) {
    if (category.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return category;
    }

    final matchingItems = category.items
        .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final matchingSubCategories = <MenuCategory>[];
    for (var sub in category.subCategories) {
      final match = _filterCategory(sub);
      if (match != null) {
        matchingSubCategories.add(match);
      }
    }

    if (matchingItems.isNotEmpty || matchingSubCategories.isNotEmpty) {
      return MenuCategory(
        id: category.id,
        name: category.name,
        items: matchingItems,
        subCategories: matchingSubCategories,
      );
    }

    return null;
  }

  void _showItemDetails(MenuItem item) {
    int quantity = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (item.image != null && item.image!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.image!.startsWith('http')
                                ? item.image!
                                : "${ApiService.baseHostUrl}${item.image!.startsWith('/') ? '' : '/'}${item.image!}",
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.restaurant, color: Color(0xFFFFC107), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Rs ${item.price}", style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("Quantity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            onPressed: () {
                              if (quantity > 1) {
                                setSheetState(() => quantity--);
                              }
                            },
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: quantity > 1 ? Colors.red.shade400 : Colors.grey.shade300,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Text("$quantity", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 32),
                          IconButton.filled(
                            onPressed: () => setSheetState(() => quantity++),
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _tableService.addToCart(widget.tableNumber, item, quantity);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Add to Order - Rs ${item.price * quantity}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredMenu();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Place Order", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search dishes, drinks...",
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final category = filteredData[index];
                      return _buildCategorySection(category);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tableService,
        builder: (context, _) {
          final cartItems = _tableService.getCart(widget.tableNumber);
          if (cartItems.isEmpty) return const SizedBox.shrink();

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ElevatedButton.icon(
              onPressed: () {
                String tableName = _tableService.getTableName(widget.tableNumber);
                if (widget.orderType != null && widget.customerName != null && widget.customerName!.isNotEmpty) {
                  tableName = '${widget.orderType} • ${widget.customerName}';
                } else if (widget.orderType != null) {
                  tableName = widget.orderType!;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderOverviewScreen(
                      tableId: widget.tableNumber,
                      tableName: tableName,
                      navigationItems: widget.navigationItems,
                      orderType: widget.orderType,
                      customerName: widget.customerName,
                      deliveryPartnerId: widget.deliveryPartnerId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout, color: Colors.black87),
              label: Text("Review Order (${cartItems.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCategorySection(MenuCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(category.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: category.items.length,
          itemBuilder: (context, index) => _buildItemCard(category.items[index]),
        ),
        ...category.subCategories.map((sub) => _buildCategorySection(sub)),
      ],
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return ListenableBuilder(
      listenable: _tableService,
      builder: (context, _) {
        final cart = _tableService.getCart(widget.tableNumber);
        final cartItem = cart.firstWhere((e) => e.menuItem.id == item.id, orElse: () => CartItem(menuItem: item, quantity: 0));
        final hasAny = cartItem.quantity > 0;

        return GestureDetector(
          onTap: () => _showItemDetails(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: hasAny ? const Color(0xFFFFC107) : Colors.transparent, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: item.image != null && item.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.image!.startsWith('http') 
                                  ? item.image! 
                                  : "${ApiService.baseHostUrl}${item.image!.startsWith('/') ? '' : '/'}${item.image!}", 
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            ),
                          )
                        : Icon(Icons.fastfood, color: Colors.grey[200], size: 40),
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rs ${item.price}", style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 14)),
                    if (hasAny)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(8)),
                        child: Text("x${cartItem.quantity}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      const Icon(Icons.add_circle, color: Color(0xFFFFC107), size: 24),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

