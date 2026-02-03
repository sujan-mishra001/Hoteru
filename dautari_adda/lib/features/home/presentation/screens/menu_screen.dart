import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/home/data/menu_data.dart';
import 'package:dautari_adda/features/home/data/menu_service.dart';

import 'package:dautari_adda/features/home/data/table_service.dart';
import 'package:dautari_adda/features/home/presentation/screens/bill_screen.dart';

class MenuScreen extends StatefulWidget {
  final int tableNumber;
  final String? initialSearch;
  final bool isOrderingMode;
  final List<Map<String, dynamic>>? navigationItems;

  const MenuScreen({
    super.key, 
    required this.tableNumber, 
    this.initialSearch,
    this.isOrderingMode = true,
    this.navigationItems,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  final TableService _tableService = TableService();
  late final TextEditingController _searchController;
  String _searchQuery = "";
  List<MenuCategory> _fullMenu = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearch ?? "";
    _searchController = TextEditingController(text: _searchQuery);
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    _menuService.getMenuStream().listen((data) {
      if (mounted) {
        setState(() {
          _fullMenu = data;
          _isLoading = false;
        });
      }
    });
  }

  void _loadData() async {
    final data = await _menuService.getMenu();
    if (mounted) {
      setState(() {
        _fullMenu = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // If category name matches, return it entirely (optional: or still filter items?)
    // Let's say if category matches, show all.
    if (category.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return category; 
    }

    // Otherwise check items and subcategories
    final matchingItems = category.items.where((item) => 
      item.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    final matchingSubCategories = <MenuCategory>[];
    for (var sub in category.subCategories) {
      final match = _filterCategory(sub);
      if (match != null) {
        matchingSubCategories.add(match);
      }
    }

    if (matchingItems.isNotEmpty || matchingSubCategories.isNotEmpty) {
      return MenuCategory(
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFFFC107),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Rs ${item.price}",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      "Quantity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            onPressed: () {
                              if (quantity > 1) {
                                setSheetState(() {
                                  quantity--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: quantity > 1 ? Colors.red.shade400 : Colors.grey.shade300,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$quantity",
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 32),
                          IconButton.filled(
                            onPressed: () {
                              setSheetState(() {
                                quantity++;
                              });
                            },
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: Colors.black,
                            ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item.name} added to cart"),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Text(
                          "Add to Order - Rs ${item.price * quantity}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isOrderingMode ? "Place Order" : "Menu Directory",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined, color: Colors.black54),
            tooltip: "Management Mode",
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          if (widget.isOrderingMode)
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded, color: Colors.black54),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BillScreen(tableNumber: widget.tableNumber)));
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // SaaS Context Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.table_restaurant_rounded, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Serving Table",
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w500),
                            ),
                            if (widget.isOrderingMode)
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: widget.tableNumber,
                                  isDense: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MenuScreen(
                                            tableNumber: newValue,
                                            isOrderingMode: true,
                                            navigationItems: widget.navigationItems,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  items: _tableService.tables.map<DropdownMenuItem<int>>((TableInfo table) {
                                    return DropdownMenuItem<int>(
                                      value: table.id,
                                      child: Text(table.tableId),
                                    );
                                  }).toList(),
                                ),
                              )
                            else
                              Text("Public View", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search dishes, drinks...",
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text("Create New Root Category", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final cat = filteredData[index];
                      return _buildCategoryTile(cat, cat);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: !widget.isOrderingMode ? null : ListenableBuilder(
        listenable: _tableService,
        builder: (context, _) {
          final total = _tableService.getTableTotal(widget.tableNumber);
          final itemCount = _tableService.getCart(widget.tableNumber).length;
          
          if (itemCount == 0) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () async {
               final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BillScreen(
                    tableNumber: widget.tableNumber,
                    navigationItems: widget.navigationItems,
                  ),
                ),
              );
               if (result is int) {
                Navigator.pop(context, result);
              }
            },
            backgroundColor: Colors.black87,
            elevation: 4,
            icon: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 20),
            label: Text(
              "View Cart • Rs ${total.toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCategoryTile(MenuCategory category, MenuCategory rootCategory) {
    // Only hide empty categories if NOT in edit mode
    if (!_isEditMode && category.subCategories.isEmpty && category.items.isEmpty) {
      if (category.name != "Drink" && category.name != "Smoking") return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: _searchQuery.isNotEmpty && category.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: rootCategory == category ? FontWeight.bold : FontWeight.w600, 
            fontSize: rootCategory == category ? 17 : 15, 
            color: Colors.black87
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (rootCategory == category ? const Color(0xFFFFC107) : Colors.blueGrey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            rootCategory == category ? Icons.restaurant_menu_rounded : Icons.label_important_outline_rounded, 
            color: rootCategory == category ? const Color(0xFFFFC107) : Colors.blueGrey, 
            size: rootCategory == category ? 18 : 16
          ),
        ),
        trailing: _isEditMode 
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
                onSelected: (value) {
                  switch (value) {
                    case 'edit': _showEditCategoryDialog(category, rootCategory); break;
                    case 'delete': _confirmDeleteCategory(category, rootCategory); break;
                    case 'sub': _showAddCategoryDialog(parent: category, rootCategory: rootCategory); break;
                    case 'item': _showAddItemDialog(category, rootCategory); break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, color: Colors.orange), title: Text("Rename"), dense: true)),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, color: Colors.red), title: Text("Delete"), dense: true)),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'sub', child: ListTile(leading: Icon(Icons.add_circle_outline_rounded, color: Colors.blue), title: Text("Add Sub-category"), dense: true)),
                  const PopupMenuItem(value: 'item', child: ListTile(leading: Icon(Icons.add_box_outlined, color: Colors.green), title: Text("Add Dish"), dense: true)),
                ],
              )
            : null,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        backgroundColor: Colors.white,
        children: [
          ...category.subCategories.map((sub) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildCategoryTile(sub, rootCategory), // Pass root down
          )),
          if(category.items.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6, 
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: category.items.length,
              itemBuilder: (context, index) {
                final item = category.items[index];
                return ListenableBuilder(
                  listenable: _tableService,
                  builder: (context, _) {
                    final cartItems = _tableService.getCart(widget.tableNumber);
                    final cartItem = cartItems.firstWhere(
                      (element) => element.menuItem.name == item.name,
                      orElse: () => CartItem(menuItem: item, quantity: 0),
                    );
                    final int quantity = cartItem.quantity;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isOrderingMode 
                            ? () => _showItemDetails(item) 
                            : (_isEditMode ? () => _showEditItemDialog(item, category, rootCategory) : null),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (widget.isOrderingMode && quantity > 0) ? const Color(0xFFFFC107) : const Color(0xFFFFC107).withOpacity(0.2),
                              width: (widget.isOrderingMode && quantity > 0) ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isOrderingMode && quantity > 0) ? const Color(0xFFFFC107).withOpacity(0.15) : const Color(0xFFFFC107).withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.black87,
                                              height: 1.1,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_isEditMode && !widget.isOrderingMode)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: GestureDetector(
                                              onTap: () => _confirmDeleteItem(item, category, rootCategory),
                                              child: const Icon(Icons.remove_circle_rounded, size: 18, color: Colors.redAccent),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rs ${item.price}",
                                      style: const TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.isOrderingMode && quantity > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "x$quantity",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (widget.isOrderingMode)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFFFFC107)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog({MenuCategory? parent, MenuCategory? rootCategory}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parent == null ? "Add Main Category" : "Add Sub-category to ${parent.name}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Category Name", hintText: "e.g. Desserts"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              
              if (parent == null) {
                await _menuService.addCategory(controller.text.trim(), 'KOT');
              } else {
                // Sub-categories are Menu Groups in the backend
                await _menuService.addMenuGroup({
                  'name': controller.text.trim(),
                  'category_id': parent.id,
                  'description': 'Created via Mobile App'
                });
              }
              Navigator.pop(context);
              _loadData(); // Manually refresh
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(MenuCategory category, MenuCategory rootCategory) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Dish to ${category.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name"), autofocus: true),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price (Rs)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) return;
              
              final itemData = {
                'name': nameController.text.trim(),
                'price': double.tryParse(priceController.text) ?? 0.0,
                'category_id': rootCategory.id,
                'group_id': category != rootCategory ? category.id : null,
                'kot_bot': 'KOT', // Default
              };
              
              await _menuService.addMenuItem(itemData);
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Recursive Helper to update a category within a hierarchy
  MenuCategory _updateCategoryInHierarchy({
    required MenuCategory root,
    required String targetName,
    required MenuCategory Function(MenuCategory) updateFn,
  }) {
    if (root.name == targetName) {
      return updateFn(root);
    }

    return MenuCategory(
      name: root.name,
      items: root.items,
      subCategories: root.subCategories.map((sub) => _updateCategoryInHierarchy(
        root: sub,
        targetName: targetName,
        updateFn: updateFn,
      )).toList(),
    );
  }

  void _showEditCategoryDialog(MenuCategory category, MenuCategory rootCategory) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Category Name"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "New Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final newName = controller.text.trim();
              
              if (category.id != null) {
                if (category == rootCategory) {
                  await _menuService.updateCategory(category.id!, newName);
                } else {
                  await _menuService.updateMenuGroup(category.id!, {'name': newName});
                }
              }
              
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(MenuCategory category, MenuCategory rootCategory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text("Are you sure you want to delete '${category.name}' and all its items?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (category.id != null) {
                if (category == rootCategory) {
                  await _menuService.deleteCategory(category.id!);
                } else {
                  await _menuService.deleteMenuGroup(category.id!);
                }
              }
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  MenuCategory _removeCategoryFromHierarchy(MenuCategory root, String targetName) {
    return MenuCategory(
      name: root.name,
      items: root.items,
      subCategories: root.subCategories
          .where((sub) => sub.name != targetName)
          .map((sub) => _removeCategoryFromHierarchy(sub, targetName))
          .toList(),
    );
  }

  void _showEditItemDialog(MenuItem item, MenuCategory category, MenuCategory rootCategory) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (item.id != null) {
                final updatedItemData = {
                  'name': nameController.text.trim(),
                  'price': double.tryParse(priceController.text) ?? 0.0,
                };
                await _menuService.updateMenuItem(item.id!, updatedItemData);
              }
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(MenuItem item, MenuCategory category, MenuCategory rootCategory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Are you sure you want to delete '${item.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (item.id != null) {
                await _menuService.deleteMenuItem(item.id!);
              }
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
