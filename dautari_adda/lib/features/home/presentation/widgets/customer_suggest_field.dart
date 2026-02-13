import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dautari_adda/features/customers/data/customer_service.dart';

/// Text field with customer name/phone suggestions as user types.
/// When no match found, shows option to add new customer.
class CustomerSuggestField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final ValueChanged<String>? onSelected;
  /// Called when user taps "Add customer" - parent should show add customer form
  final VoidCallback? onAddCustomerRequested;

  const CustomerSuggestField({
    super.key,
    required this.controller,
    this.labelText = 'Customer Name or Phone',
    this.hintText = 'Type name or number...',
    this.onSelected,
    this.onAddCustomerRequested,
  });

  @override
  State<CustomerSuggestField> createState() => _CustomerSuggestFieldState();
}

class _CustomerSuggestFieldState extends State<CustomerSuggestField> {
  final CustomerService _customerService = CustomerService();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isSelectingSuggestion = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_isSelectingSuggestion) return;
    _debounce?.cancel();
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showDropdown = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetchSuggestions(text));
  }

  Future<void> _fetchSuggestions(String query) async {
    final list = await _customerService.getCustomers(search: query);
    if (mounted && !_isSelectingSuggestion) {
      setState(() {
        _suggestions = List<Map<String, dynamic>>.from(list);
        _showDropdown = true;
      });
    }
  }

  void _onAddCustomerTap() {
    widget.onAddCustomerRequested?.call();
  }

  void _selectSuggestion(Map<String, dynamic> customer) {
    final name = customer['name']?.toString() ?? '';
    _isSelectingSuggestion = true;
    _debounce?.cancel();
    widget.controller.text = name;
    widget.controller.selection = TextSelection.collapsed(offset: name.length);
    setState(() {
      _suggestions = [];
      _showDropdown = false;
    });
    widget.onSelected?.call(name);
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _isSelectingSuggestion = false;
    });
  }

  void _closeDropdown() {
    setState(() {
      _suggestions = [];
      _showDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showAddOption = _showDropdown &&
        _suggestions.isEmpty &&
        widget.controller.text.trim().isNotEmpty &&
        widget.onAddCustomerRequested != null;
    final showDropdown = _showDropdown && (_suggestions.isNotEmpty || showAddOption);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _showDropdown
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _closeDropdown,
                    tooltip: 'Close',
                  )
                : null,
          ),
          onTap: () {
            final text = widget.controller.text.trim();
            if (text.isNotEmpty && !_isSelectingSuggestion) {
              _fetchSuggestions(text);
            }
          },
          onTapOutside: (_) {
            // Don't close immediately - allow time for suggestion tap
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && !_isSelectingSuggestion) {
                _closeDropdown();
              }
            });
          },
        ),
        if (showDropdown) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length + (showAddOption ? 1 : 0),
                itemBuilder: (context, index) {
                  if (showAddOption && index == _suggestions.length) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.person_add_rounded, color: Colors.green[700], size: 24),
                      title: Text(
                        'Add "${widget.controller.text.trim()}" as new customer',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onTap: () {
                        _isSelectingSuggestion = true;
                        _onAddCustomerTap();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _isSelectingSuggestion = false;
                        });
                      },
                    );
                  }
                  final c = _suggestions[index];
                  final name = c['name'] ?? 'Unknown';
                  final phone = c['phone'] ?? '';
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectSuggestion(c),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.amber.shade100,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: phone.isNotEmpty ? Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
