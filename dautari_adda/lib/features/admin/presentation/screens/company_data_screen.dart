import 'package:flutter/material.dart';
import 'package:dautari_adda/core/api/api_service.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: const Color(0xFFF8F9FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _error != null
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 24),
          Text(
            "Oops! Something went wrong",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadCompanyData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Basic Information", Icons.info_outline_rounded),
                _buildInfoGroup([
                  _buildDetailTile(Icons.business_rounded, "Company Name", _companyData?['company_name']),
                  _buildDetailTile(Icons.email_outlined, "Email Address", _companyData?['email']),
                  _buildDetailTile(Icons.phone_outlined, "Phone Number", _companyData?['phone']),
                  _buildDetailTile(Icons.location_on_outlined, "Headquarters", _companyData?['address']),
                ]),
                const SizedBox(height: 32),
                _buildSectionHeader("Tax & Compliance", Icons.verified_user_outlined),
                _buildInfoGroup([
                  _buildDetailTile(Icons.assignment_ind_outlined, "VAT/PAN No.", _companyData?['vat_pan_no']),
                  _buildDetailTile(Icons.app_registration_rounded, "Registration No.", _companyData?['registration_no']),
                  _buildDetailTile(Icons.receipt_long_outlined, "Invoice Prefix", _companyData?['invoice_prefix']),
                ]),
                const SizedBox(height: 32),
                _buildSectionHeader("Billing & Charges", Icons.payments_outlined),
                _buildInfoGroup([
                  _buildDetailTile(Icons.currency_exchange_rounded, "Currency", _companyData?['currency']),
                  _buildDetailTile(Icons.percent_rounded, "Tax Rate", "${_companyData?['tax_rate']}%"),
                  _buildDetailTile(Icons.room_service_outlined, "Service Charge", "${_companyData?['service_charge_rate']}%"),
                  _buildDetailTile(Icons.discount_outlined, "Default Discount", "${_companyData?['discount_rate']}%"),
                ]),
                const SizedBox(height: 32),
                _buildSectionHeader("Additional Details", Icons.more_horiz_rounded),
                _buildInfoGroup([
                  _buildDetailTile(Icons.schedule_rounded, "Timezone", _companyData?['timezone']),
                  _buildDetailTile(Icons.calendar_today_outlined, "Member Since", _formatDate(_companyData?['created_at'])),
                  _buildDetailTile(Icons.update_rounded, "Last Updated", _formatDate(_companyData?['updated_at'])),
                ]),
                if (_companyData?['invoice_footer_text'] != null && _companyData?['invoice_footer_text'].toString().isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader("Invoice Footer", Icons.short_text_rounded),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      _companyData?['invoice_footer_text'],
                      style: GoogleFonts.poppins(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFFFC107),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          onPressed: _loadCompanyData,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          "Company Profile",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.business_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFFC107)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, dynamic value) {
    final displayValue = (value == null || value.toString().isEmpty || value.toString() == "null") ? "Not set" : value.toString();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFFFC107)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                Text(
                  displayValue,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }
}

