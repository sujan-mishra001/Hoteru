import 'package:flutter/material.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:dautari_adda/features/home/data/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _currency = 'NPR';
  double _taxRate = 13.0;
  bool _autoPrint = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getSettings();
      if (settings.isNotEmpty) {
        setState(() {
          _notificationsEnabled = settings['notifications_enabled'] ?? true;
          _soundEnabled = settings['sound_enabled'] ?? true;
          _vibrationEnabled = settings['vibration_enabled'] ?? true;
          _currency = settings['currency'] ?? 'NPR';
          _taxRate = (settings['tax_rate'] ?? 13.0).toDouble();
          _autoPrint = settings['auto_print'] ?? false;
          _darkMode = settings['dark_mode'] ?? false;
        });
      }
    } catch (e) {
      // Use defaults if settings can't be loaded
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final success = await _service.updateSettings({
        'notifications_enabled': _notificationsEnabled,
        'sound_enabled': _soundEnabled,
        'vibration_enabled': _vibrationEnabled,
        'currency': _currency,
        'tax_rate': _taxRate,
        'auto_print': _autoPrint,
        'dark_mode': _darkMode,
      });

      if (success) {
        if (mounted) ToastService.showSuccess(context, 'Settings saved successfully');
      } else {
        if (mounted) ToastService.showError(context, 'Failed to save settings');
      }
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Error saving settings');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading && _notificationsEnabled
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Settings
                  const Text('Business Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.attach_money),
                          title: const Text('Currency'),
                          subtitle: const Text('Select your currency'),
                          trailing: DropdownButton<String>(
                            value: _currency,
                            items: ['NPR', 'USD', 'INR', 'EUR', 'GBP'].map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            )).toList(),
                            onChanged: (value) => setState(() => _currency = value!),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.percent),
                          title: const Text('Tax Rate (%)'),
                          subtitle: Text(_taxRate.toStringAsFixed(1)),
                          trailing: SizedBox(
                            width: 120,
                            child: Slider(
                              value: _taxRate,
                              min: 0,
                              max: 30,
                              divisions: 60,
                              onChanged: (value) => setState(() => _taxRate = value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Printer Settings
                  const Text('Printer Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.print),
                          title: const Text('Auto Print Receipt'),
                          subtitle: const Text('Automatically print after each sale'),
                          value: _autoPrint,
                          onChanged: (value) => setState(() => _autoPrint = value),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Notification Settings
                  const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications),
                          title: const Text('Enable Notifications'),
                          value: _notificationsEnabled,
                          onChanged: (value) => setState(() => _notificationsEnabled = value),
                        ),
                        const Divider(),
                        SwitchListTile(
                          secondary: const Icon(Icons.volume_up),
                          title: const Text('Sound'),
                          subtitle: const Text('Play sound on notifications'),
                          value: _soundEnabled,
                          onChanged: _notificationsEnabled ? (value) => setState(() => _soundEnabled = value) : null,
                        ),
                        const Divider(),
                        SwitchListTile(
                          secondary: const Icon(Icons.vibration),
                          title: const Text('Vibration'),
                          subtitle: const Text('Vibrate on notifications'),
                          value: _vibrationEnabled,
                          onChanged: _notificationsEnabled ? (value) => setState(() => _vibrationEnabled = value) : null,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App Settings
                  const Text('App Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode),
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Use dark theme'),
                          value: _darkMode,
                          onChanged: (value) => setState(() => _darkMode = value),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.info),
                          title: Text('Version'),
                          subtitle: Text('1.0.0'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('Privacy Policy'),
                          onTap: () => ToastService.showInfo(context, 'Privacy Policy'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Terms of Service'),
                          onTap: () => ToastService.showInfo(context, 'Terms of Service'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
