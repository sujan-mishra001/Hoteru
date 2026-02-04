import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/menu_data.dart';
import 'package:dautari_adda/features/pos/data/menu_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuService _menuService = MenuService();
  List<MenuCategory> _menu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    final data = await _menuService.getMenu();
    if (mounted) {
      setState(() {
        _menu = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Menu Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCategoryDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Create Root Category", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: _menu.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _menu.length,
                          itemBuilder: (context, index) {
                            return _buildRootCategoryTile(_menu[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No menu categories found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRootCategoryTile(MenuCategory category) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ExpansionTile(
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("Type: ${category.type}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFFFC107).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.folder_rounded, color: Color(0xFFFFC107), size: 20),
        ),
        trailing: _buildActionsMenu(
          onEdit: () => _showCategoryDialog(category: category),
          onDelete: () => _confirmDelete(category: category),
          onAddSub: () => _showSubCategoryDialog(parent: category),
          onAddItem: () => _showItemDialog(categoryId: category.id!, rootId: category.id!),
        ),
        children: [
          ...category.subCategories.map((sub) => _buildSubCategoryTile(sub, category.id!)),
          ...category.items.map((item) => _buildItemTile(item)),
          if (category.subCategories.isEmpty && category.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Empty Category", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryTile(MenuCategory sub, int rootId) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ExpansionTile(
        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Colors.grey),
        trailing: _buildActionsMenu(
          onEdit: () => _showSubCategoryDialog(parent: MenuCategory(id: rootId, name: ''), sub: sub),
          onDelete: () => _confirmDelete(sub: sub),
          onAddItem: () => _showItemDialog(categoryId: rootId, groupId: sub.id, rootId: rootId),
        ),
        children: sub.items.map((item) => _buildItemTile(item)).toList(),
      ),
    );
  }

  Widget _buildItemTile(MenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      title: Text(item.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text("Rs ${item.price} • ${item.kotBot}", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
            onPressed: () => _showItemDialog(rootId: item.categoryId!, existingItem: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            onPressed: () => _confirmDelete(item: item),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    VoidCallback? onAddSub,
    required VoidCallback onAddItem,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (val) {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
        if (val == 'add_sub') onAddSub?.call();
        if (val == 'add_item') onAddItem();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded, size: 18), title: Text("Edit"), dense: true)),
        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_rounded, size: 18, color: Colors.red), title: Text("Delete"), dense: true)),
        if (onAddSub != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'add_sub', child: ListTile(leading: Icon(Icons.add_circle_outline, size: 18), title: Text("Add Sub-category"), dense: true)),
        ],
        const PopupMenuItem(value: 'add_item', child: ListTile(leading: Icon(Icons.add_box_outlined, size: 18), title: Text("Add Item"), dense: true)),
      ],
    );
  }

  // DIALOGS

  void _showCategoryDialog({MenuCategory? category}) {
    final nameController = TextEditingController(text: category?.name);
    String selectedType = category?.type ?? 'KOT';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? "Create Category" : "Edit Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Category Name"), autofocus: true),
              const SizedBox(height: 16),
              const Text("Print Destination:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("KOT"),
                      value: 'KOT',
                      groupValue: selectedType,
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("BOT"),
                      value: 'BOT',
                      groupValue: selectedType,
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                bool success;
                if (category == null) {
                  success = await _menuService.addCategory(nameController.text.trim(), selectedType);
                } else {
                  success = await _menuService.updateCategory(category.id!, nameController.text.trim());
                  // Note: type update might need backend support if category type is changed
                }
                if (success) {
                  Navigator.pop(context);
                  _loadMenu();
                }
              },
              child: Text(category == null ? "Create" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubCategoryDialog({required MenuCategory parent, MenuCategory? sub}) {
    final controller = TextEditingController(text: sub?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sub == null ? "Add Sub-category" : "Edit Sub-category"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Sub-category Name"), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              bool success;
              if (sub == null) {
                success = await _menuService.addMenuGroup({
                  'name': controller.text.trim(),
                  'category_id': parent.id,
                });
              } else {
                success = await _menuService.updateMenuGroup(sub.id!, {'name': controller.text.trim()});
              }
              if (success) {
                Navigator.pop(context);
                _loadMenu();
              }
            },
            child: Text(sub == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({required int rootId, int? categoryId, int? groupId, MenuItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name);
    final priceController = TextEditingController(text: existingItem?.price.toString());
    String kotBot = existingItem?.kotBot ?? 'KOT';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingItem == null ? "Add Item" : "Edit Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name"), autofocus: true),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              const Text("Print Type:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("KOT"),
                      value: 'KOT',
                      groupValue: kotBot,
                      onChanged: (v) => setDialogState(() => kotBot = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("BOT"),
                      value: 'BOT',
                      groupValue: kotBot,
                      onChanged: (v) => setDialogState(() => kotBot = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                bool success;
                final data = {
                  'name': nameController.text.trim(),
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'kot_bot': kotBot,
                  'category_id': categoryId ?? existingItem?.categoryId,
                  'group_id': groupId ?? existingItem?.groupId,
                };

                if (existingItem == null) {
                  success = await _menuService.addMenuItem(data);
                } else {
                  success = await _menuService.updateMenuItem(existingItem.id!, data);
                }
                if (success) {
                  Navigator.pop(context);
                  _loadMenu();
                }
              },
              child: Text(existingItem == null ? "Add" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete({MenuCategory? category, MenuCategory? sub, MenuItem? item}) {
    String name = category?.name ?? sub?.name ?? item?.name ?? "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete '$name'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              bool success = false;
              if (category != null) success = await _menuService.deleteCategory(category.id!);
              if (sub != null) success = await _menuService.deleteMenuGroup(sub.id!);
              if (item != null) success = await _menuService.deleteMenuItem(item.id!);
              
              if (success) {
                Navigator.pop(context);
                _loadMenu();
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}