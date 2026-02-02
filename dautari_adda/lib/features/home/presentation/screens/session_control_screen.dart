import 'package:flutter/material.dart';
import 'package:dautari_adda/features/home/data/session_service.dart';
import 'package:dautari_adda/features/home/data/branch_service.dart';
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
    setState(() => _isLoading = true);
    
    final sessionsFuture = _sessionService.getSessions();
    final branchesFuture = _branchService.getBranches();
    final activeSessionFuture = _sessionService.getActiveSession();
    
    final results = await Future.wait([
      sessionsFuture, 
      branchesFuture, 
      activeSessionFuture
    ]);
    
    setState(() {
      _sessions = results[0] as List<dynamic>;
      _branches = results[1] as List<dynamic>;
      _activeSession = results[2] as Map<String, dynamic>?;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Control'),
        backgroundColor: const Color(0xFFFFC107),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActiveSessionCard(),
                  const SizedBox(height: 24),
                  _buildOpenSessionButton(),
                  const SizedBox(height: 24),
                  _buildSessionHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveSessionCard() {
    if (_activeSession == null) {
      return Card(
        elevation: 4,
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.lock_open, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Active Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open a new session to start taking orders',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final session = _activeSession!;
    final startTime = DateTime.parse(session['start_time']);
    final formattedTime = DateFormat('hh:mm a').format(startTime);

    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Active Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSessionDetail('Started At', formattedTime),
            _buildSessionDetail('Opening Cash', 'Rs. ${session['opening_cash']}'),
            if (session['notes'] != null)
              _buildSessionDetail('Notes', session['notes']),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _showCloseSessionDialog(session),
              child: const Text('Close Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOpenSessionButton() {
    if (_activeSession != null) return const SizedBox();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () => _showOpenSessionDialog(),
      child: const Text(
        'OPEN NEW SESSION',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showOpenSessionDialog() {
    final cashController = TextEditingController(text: '0.0');
    final notesController = TextEditingController();
    int? selectedBranchId;
    if (_branches.isNotEmpty) {
      selectedBranchId = _branches[0]['id'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open New Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_branches.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  value: selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: _branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch['id'],
                      child: Text(branch['name']),
                    );
                  }).toList(),
                  onChanged: (value) => selectedBranchId = value,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: cashController,
                decoration: const InputDecoration(
                  labelText: 'Opening Cash',
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              try {
                await _sessionService.openSession(
                  openingCash: double.parse(cashController.text),
                  notes: notesController.text,
                  branchId: selectedBranchId,
                );
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('Session opened successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Open Session'),
          ),
        ],
      ),
    );
  }

  void _showCloseSessionDialog(dynamic session) {
    final closingCashController = TextEditingController(
      text: session['opening_cash'].toString()
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to close this session?',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: closingCashController,
                decoration: const InputDecoration(
                  labelText: 'Closing Cash',
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _sessionService.closeSession(
                  sessionId: session['id'],
                  closingCash: double.parse(closingCashController.text),
                  notes: notesController.text,
                );
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('Session closed successfully');
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: const Text('Close Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory() {
    final openSessions = _sessions.where((s) => s['status'] == 'Open').toList();
    final closedSessions = _sessions.where((s) => s['status'] == 'Closed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (openSessions.isNotEmpty) ...[
          const Text(
            'Active Sessions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...openSessions.map((session) => _buildSessionCard(session, isActive: true)),
          const SizedBox(height: 16),
        ],
        if (closedSessions.isNotEmpty) ...[
          const Text(
            'Session History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...closedSessions.take(10).map((session) => _buildSessionCard(session, isActive: false)),
        ],
        if (_sessions.isEmpty)
          Center(
            child: Column(
              children: [
                const Icon(Icons.history, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('No session history', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSessionCard(dynamic session, {required bool isActive}) {
    final startTime = DateTime.parse(session['start_time']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(startTime);
    final formattedTime = DateFormat('hh:mm a').format(startTime);
    
    String statusText;
    Color statusColor;
    if (isActive) {
      statusText = 'Active';
      statusColor = Colors.green;
    } else {
      statusText = 'Closed';
      statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            isActive ? Icons.lock_open : Icons.lock,
            color: statusColor,
          ),
        ),
        title: Text('Session #${session['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$formattedDate at $formattedTime'),
            Text('Opening Cash: Rs. ${session['opening_cash']}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showSessionDetails(session),
      ),
    );
  }

  void _showSessionDetails(dynamic session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session #${session['id']} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', session['status']),
            _buildDetailRow('Started At', session['start_time']),
            if (session['end_time'] != null)
              _buildDetailRow('Ended At', session['end_time']),
            _buildDetailRow('Opening Cash', 'Rs. ${session['opening_cash']}'),
            if (session['closing_cash'] != null)
              _buildDetailRow('Closing Cash', 'Rs. ${session['closing_cash']}'),
            if (session['total_sales'] != null)
              _buildDetailRow('Total Sales', 'Rs. ${session['total_sales']}'),
            if (session['notes'] != null)
              _buildDetailRow('Notes', session['notes']),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
