import 'package:flutter/material.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'dart:convert';

class CompanyDataScreen extends StatefulWidget {
  const CompanyDataScreen({super.key});

  @override
  State<CompanyDataScreen> createState() => _CompanyDataScreenState();
}

class _CompanyDataScreenState extends State<CompanyDataScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _companyData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.get('/settings/company');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _companyData = Map<String, dynamic>.from(data);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load company data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          title: const Text(
            'Company Data',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          backgroundColor: const Color(0xFFFFC107),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _isLoading ? null : _loadCompanyData,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCompanyData,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompanyData,
                  color: const Color(0xFFFFC107),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: _buildCompanyFields(),
                  ),
                ),
    );
  }

  List<Widget> _buildCompanyFields() {
    if (_companyData == null) return [];
    final fields = <Widget>[];
    final displayOrder = [
      'company_name',
      'email',
      'phone',
      'address',
      'vat_pan_no',
      'registration_no',
      'invoice_prefix',
      'currency',
      'timezone',
      'tax_rate',
      'service_charge_rate',
      'discount_rate',
      'invoice_footer_text',
      'created_at',
      'updated_at',
    ];
    final labels = {
      'company_name': 'Company Name',
      'email': 'Email',
      'phone': 'Phone',
      'address': 'Address',
      'vat_pan_no': 'VAT/PAN No',
      'registration_no': 'Registration No',
      'invoice_prefix': 'Invoice Prefix',
      'currency': 'Currency',
      'timezone': 'Timezone',
      'tax_rate': 'Tax Rate (%)',
      'service_charge_rate': 'Service Charge Rate (%)',
      'discount_rate': 'Discount Rate (%)',
      'invoice_footer_text': 'Invoice Footer Text',
      'created_at': 'Created At',
      'updated_at': 'Updated At',
    };
    for (final key in displayOrder) {
      if (_companyData!.containsKey(key)) {
        final value = _companyData![key];
        final displayValue = value == null || value.toString().isEmpty ? '-' : value.toString();
        fields.add(_buildInfoCard(labels[key] ?? key, displayValue));
        fields.add(const SizedBox(height: 12));
      }
    }
    for (final entry in _companyData!.entries) {
      if (!displayOrder.contains(entry.key)) {
        fields.add(_buildInfoCard(entry.key, entry.value?.toString() ?? '-'));
        fields.add(const SizedBox(height: 12));
      }
    }
    return fields;
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
