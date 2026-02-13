import 'package:flutter/material.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class CompanyDataScreen extends StatefulWidget {
  const CompanyDataScreen({super.key});

  @override
  State<CompanyDataScreen> createState() => _CompanyDataScreenState();
}

class _CompanyDataScreenState extends State<CompanyDataScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _companyData;
  Map<String, dynamic> _editedData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _vatPanController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _invoicePrefixController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _serviceChargeController = TextEditingController();
  final TextEditingController _discountRateController = TextEditingController();
  final TextEditingController _invoiceFooterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vatPanController.dispose();
    _registrationController.dispose();
    _invoicePrefixController.dispose();
    _currencyController.dispose();
    _timezoneController.dispose();
    _taxRateController.dispose();
    _serviceChargeController.dispose();
    _discountRateController.dispose();
    _invoiceFooterController.dispose();
    super.dispose();
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
            _editedData = Map<String, dynamic>.from(data);
            _isLoading = false;
          });
          _populateControllers();
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

  void _populateControllers() {
    if (_companyData == null) return;
    _nameController.text = _companyData!['company_name'] ?? '';
    _emailController.text = _companyData!['email'] ?? '';
    _phoneController.text = _companyData!['phone'] ?? '';
    _addressController.text = _companyData!['address'] ?? '';
    _vatPanController.text = _companyData!['vat_pan_no'] ?? '';
    _registrationController.text = _companyData!['registration_no'] ?? '';
    _invoicePrefixController.text = _companyData!['invoice_prefix'] ?? '';
    _currencyController.text = _companyData!['currency'] ?? 'NPR';
    _timezoneController.text = _companyData!['timezone'] ?? 'Asia/Kathmandu';
    _taxRateController.text = (_companyData!['tax_rate'] ?? 13).toString();
    _serviceChargeController.text = (_companyData!['service_charge_rate'] ?? 10).toString();
    _discountRateController.text = (_companyData!['discount_rate'] ?? 0).toString();
    _invoiceFooterController.text = _companyData!['invoice_footer_text'] ?? '';
  }

  Future<void> _saveCompanyData() async {
    setState(() => _isSaving = true);

    final data = {
      'company_name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'vat_pan_no': _vatPanController.text,
      'registration_no': _registrationController.text,
      'tax_rate': double.tryParse(_taxRateController.text) ?? 13,
      'service_charge_rate': double.tryParse(_serviceChargeController.text) ?? 10,
      'discount_rate': double.tryParse(_discountRateController.text) ?? 0,
    };

    try {
      final response = await _apiService.put('/settings/company', data);
      if (response.statusCode == 200) {
        final updated = jsonDecode(response.body);
        setState(() {
          _companyData = Map<String, dynamic>.from(updated);
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company data updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _populateControllers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _error != null
              ? _buildErrorView()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: RefreshIndicator(
                        onRefresh: _loadCompanyData,
                        color: const Color(0xFFFFC107),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(),
                              const SizedBox(height: 24),
                              _buildBasicInfoCard(),
                              const SizedBox(height: 20),
                              _buildTaxSettingsCard(),
                              const SizedBox(height: 20),
                              if (_isEditing) _buildSaveButton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: !_isLoading && _error == null
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _toggleEdit,
              backgroundColor: _isEditing ? Colors.red : const Color(0xFFFFC107),
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              label: Text(_isEditing ? 'Cancel' : 'Edit'),
            )
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
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
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFFFC107),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Company Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFD54F),
                const Color(0xFFFFC107),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.business_rounded,
              size: 60,
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCompanyData,
          ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFFFC107), const Color(0xFFFFD54F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.business, size: 40, color: Colors.black87),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyData?['company_name'] ?? 'Your Company',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _companyData?['email'] ?? 'email@company.com',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildCard(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        _buildFieldRow('Company Name', _nameController, Icons.business, 'Enter company name'),
        _buildDivider(),
        _buildFieldRow('Email Address', _emailController, Icons.email, 'company@email.com'),
        _buildDivider(),
        _buildFieldRow('Phone Number', _phoneController, Icons.phone, '+977-XXXXXXXXXX'),
        _buildDivider(),
        _buildFieldRow('Address', _addressController, Icons.location_on, 'Enter full address', maxLines: 2),
        _buildDivider(),
        _buildFieldRow('VAT/PAN Number', _vatPanController, Icons.receipt, 'Enter VAT/PAN number'),
        _buildDivider(),
        _buildFieldRow('Registration No', _registrationController, Icons.app_registration, 'Enter registration number'),
      ],
    );
  }

  Widget _buildTaxSettingsCard() {
    return _buildCard(
      title: 'Tax & Service Settings',
      icon: Icons.percent,
      children: [
        _buildNumberFieldRow('Tax Rate', _taxRateController, Icons.account_balance, '%'),
        _buildDivider(),
        _buildNumberFieldRow('Service Charge', _serviceChargeController, Icons.room_service, '%'),
        _buildDivider(),
        _buildNumberFieldRow('Discount Rate', _discountRateController, Icons.local_offer, '%'),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFC107), size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, TextEditingController controller, IconData icon, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            )
          : Row(
              crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFFFFC107)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.text.isEmpty ? '-' : controller.text,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNumberFieldRow(String label, TextEditingController controller, IconData icon, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: Colors.grey[400]),
                suffixText: suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFFFFC107)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.text.isEmpty ? '0' : controller.text}$suffix',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], height: 24, indent: 56);
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveCompanyData,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }
}
