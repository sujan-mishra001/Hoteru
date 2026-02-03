import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/customer_service.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communications'),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black87,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Bulk SMS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContactsTab(),
          BulkSMSTab(),
        ],
      ),
    );
  }
}

// Contacts Tab
class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final CustomerService _customerService = CustomerService();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _contacts = (customers as List).cast<Map<String, dynamic>>();
        _filteredContacts = _contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name = (contact['name'] ?? '').toString().toLowerCase();
        final phone = (contact['phone'] ?? '').toString().toLowerCase();
        final email = (contact['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        // Contacts List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredContacts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No contacts found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        return _buildContactCard(contact);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final name = contact['name'] ?? 'Unknown';
    final phone = contact['phone'] ?? '';
    final email = contact['email'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFC107),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(phone, style: const TextStyle(fontSize: 12)),
                ],
              ),
            if (email.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.email, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(email, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.message, color: Color(0xFFFFC107)),
                onPressed: () {
                  // TODO: Implement SMS functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Send SMS to $name')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Bulk SMS Tab
class BulkSMSTab extends StatefulWidget {
  const BulkSMSTab({super.key});

  @override
  State<BulkSMSTab> createState() => _BulkSMSTabState();
}

class _BulkSMSTabState extends State<BulkSMSTab> {
  final TextEditingController _messageController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  
  List<Map<String, dynamic>> _customers = [];
  Set<int> _selectedCustomers = {};
  bool _isLoading = true;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _customers = (customers as List)
            .where((c) => c['phone'] != null && c['phone'].toString().isNotEmpty)
            .toList()
            .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedCustomers = _customers.map((c) => c['id'] as int).toSet();
      } else {
        _selectedCustomers.clear();
      }
    });
  }

  void _sendBulkSMS() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    if (_selectedCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    // TODO: Implement bulk SMS sending
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Bulk SMS'),
        content: Text(
          'Send message to ${_selectedCustomers.length} recipients?\n\nThis feature is coming soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bulk SMS feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compose Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 160,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Recipients Selection
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Select Recipients (${_selectedCustomers.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  _selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                ),
                label: const Text('Select All'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFC107),
                ),
              ),
            ],
          ),
        ),
        
        // Recipients List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _customers.isEmpty
                  ? const Center(
                      child: Text(
                        'No customers with phone numbers found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        final customerId = customer['id'] as int;
                        final isSelected = _selectedCustomers.contains(customerId);
                        
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCustomers.add(customerId);
                                } else {
                                  _selectedCustomers.remove(customerId);
                                }
                                _selectAll = _selectedCustomers.length == _customers.length;
                              });
                            },
                            title: Text(
                              customer['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(customer['phone'] ?? ''),
                            activeColor: const Color(0xFFFFC107),
                          ),
                        );
                      },
                    ),
        ),
        
        // Send Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendBulkSMS,
              icon: const Icon(Icons.send),
              label: Text('Send to ${_selectedCustomers.length} Recipients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
