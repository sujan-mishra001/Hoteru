import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/pos/data/session_service.dart';
// Note: Assuming BranchService is available as per original file import
import 'package:dautari_adda/features/admin/data/branch_service.dart';
import 'package:intl/intl.dart';

class SessionControlScreen extends StatefulWidget {
  const SessionControlScreen({super.key});

  @override
  State<SessionControlScreen> createState() => _SessionControlScreenState();
}

class _SessionControlScreenState extends State<SessionControlScreen> {
  final SessionService _sessionService = SessionService();
  final BranchService _branchService = BranchService();

  List<dynamic> _sessions = [];
  List<dynamic> _branches = [];
  Map<String, dynamic>? _activeSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final sessionsFuture = _sessionService.getSessions();
      final branchesFuture = _branchService.getBranches();
      final activeSessionFuture = _sessionService.getActiveSession();

      final results = await Future.wait([
        sessionsFuture,
        branchesFuture,
        activeSessionFuture
      ]);

      if (mounted) {
        setState(() {
          _sessions = results[0] as List<dynamic>;
          _branches = results[1] as List<dynamic>;
          _activeSession = results[2] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        toolbarHeight: 75,
        centerTitle: false,
        title: Text(
          'Session Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActiveSessionSection(),
              const SizedBox(height: 32),
              Text(
                'History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildSessionHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionSection() {
    if (_activeSession == null) {
      return _buildEmptyState();
    }
    return _buildActiveSessionCard(_activeSession!);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Session',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new session to begin taking orders and tracking sales.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showOpenSessionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Start New Session',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard(Map<String, dynamic> session) {
    final startTime = DateTime.parse(session['start_time']);
    final formattedTime = DateFormat('hh:mm a').format(startTime);
    final formattedDate = DateFormat('EEE, MMM d').format(startTime);
    final openingCash = double.tryParse(session['opening_cash'].toString()) ?? 0.0;
    final totalSales = double.tryParse(session['total_sales']?.toString() ?? '0.0') ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE NOW',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE SALES',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rs. ${totalSales.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem(
                        icon: Icons.access_time_filled_rounded,
                        label: 'Started at',
                        value: formattedTime,
                        isLight: true,
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                      _buildMetricItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Opening Cash',
                        value: 'Rs. ${openingCash.toStringAsFixed(0)}',
                        isLight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showSessionDetails(session),
                    icon: Icon(Icons.info_outline_rounded, color: Colors.grey[700]),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCloseSessionDialog(session),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50], // Light red
                      foregroundColor: Colors.red[700], // Dark red text
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(
                      'End Session',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLight = false,
  }) {
    final color = isLight ? Colors.white : Colors.black87;
    final subtitleColor = isLight ? Colors.white.withOpacity(0.7) : Colors.grey[600];

    return Row(
      children: [
        Icon(icon, size: 20, color: subtitleColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionHistory() {
    // Filter closed sessions
    final history = _sessions.where((s) => s['status'] == 'Closed').toList();

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No session history found',
                style: GoogleFonts.inter(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length > 10 ? 10 : history.length, // Show last 10
      itemBuilder: (context, index) {
        final session = history[index];
        final startTime = DateTime.parse(session['start_time']);
        final endTime = session['end_time'] != null ? DateTime.parse(session['end_time']) : null;
        final totalSales = double.tryParse(session['total_sales']?.toString() ?? '0') ?? 0;
        final user = session['user'];
        final userName = user != null ? user['full_name'] : 'Unknown User';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () => _showSessionDetails(session),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[100],
              child: const Icon(Icons.receipt_long_rounded, color: Colors.grey),
            ),
            title: Text(
              'Rs. ${totalSales.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                 Text(
                  endTime != null 
                    ? '${DateFormat('MMM d').format(startTime)} • ${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}'
                    : DateFormat('MMM d, h:mm a').format(startTime),
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Closed',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialogs
  void _showOpenSessionDialog() {
    final cashController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    int? selectedBranchId;
    if (_branches.isNotEmpty) {
      selectedBranchId = _branches[0]['id'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Start New Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_branches.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  value: selectedBranchId,
                  decoration: InputDecoration(
                    labelText: 'Branch',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _branches.map<DropdownMenuItem<int>>((branch) {
                    return DropdownMenuItem<int>(
                      value: branch['id'] as int,
                      child: Text(branch['name']),
                    );
                  }).toList(),
                  onChanged: (value) => selectedBranchId = value,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: cashController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Opening Cash Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await _sessionService.openSession(
                  openingCash: double.parse(cashController.text),
                  notes: notesController.text,
                  branchId: selectedBranchId,
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('Session started successfully!');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: Text('Start Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCloseSessionDialog(dynamic session) {
    final openingCash = (session['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final totalSales = (session['total_sales'] as num?)?.toDouble() ?? 0.0;
    final defaultClosing = openingCash + totalSales;
    
    final closingCashController = TextEditingController(text: defaultClosing.toStringAsFixed(2));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Opening Balance: Rs ${openingCash.toStringAsFixed(2)}", 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text("Total Sales: Rs ${totalSales.toStringAsFixed(2)}", 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    const Divider(),
                    Text("Expected Closing: Rs ${defaultClosing.toStringAsFixed(2)}", 
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ensure all cash is counted before closing.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: closingCashController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Closing Cash Count',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Closing Notes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
           TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await _sessionService.closeSession(
                  sessionId: session['id'],
                  closingCash: double.parse(closingCashController.text.isEmpty ? defaultClosing.toString() : closingCashController.text),
                  notes: notesController.text,
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _loadData();
                 _showSuccessSnackBar('Session closed successfully');
              } catch (e) {
                 _showErrorSnackBar(e.toString());
              }
            },
            child: Text('End Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(dynamic session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Session Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', session['status']),
            _buildDetailRow('Branch', session['branch']?['name'] ?? 'N/A'),
            const Divider(),
            _buildDetailRow('Started', _formatDate(session['start_time'])),
            if (session['end_time'] != null)
              _buildDetailRow('Ended', _formatDate(session['end_time'])),
             const Divider(),
            _buildDetailRow('Opening Cash', 'Rs. ${session['opening_cash']}'),
            if (session['closing_cash'] != null)
              _buildDetailRow('Closing Cash', 'Rs. ${session['closing_cash']}'),
            _buildDetailRow('Total Sales', 'Rs. ${session['total_sales'] ?? 0}'),
            if (session['notes'] != null && session['notes'].toString().isNotEmpty) ...[
              const Divider(),
              Text('Notes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(session['notes'].toString(), style: GoogleFonts.inter(fontSize: 14)),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
}
