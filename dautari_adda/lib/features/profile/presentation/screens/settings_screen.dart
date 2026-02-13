import 'package:flutter/material.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'package:dautari_adda/features/profile/data/settings_service.dart';
import 'package:dautari_adda/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/features/admin/presentation/screens/printer_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();
  bool _isLoading = false;
  
  // App Preferences
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode = ThemeProvider().isDarkMode;
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
        });
        
        // Save to local storage for immediate service access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', _notificationsEnabled);
        await prefs.setBool('sound_enabled', _soundEnabled);
        await prefs.setBool('vibration_enabled', _vibrationEnabled);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final success = await _service.updateSettings({
        'company_name': 'Dautari Adda', // Required by backend schema
        'notifications_enabled': _notificationsEnabled,
        'sound_enabled': _soundEnabled,
        'vibration_enabled': _vibrationEnabled,
        'dark_mode': _darkMode,
      });

      if (success) {
        // Save to local storage for services
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', _notificationsEnabled);
        await prefs.setBool('sound_enabled', _soundEnabled);
        await prefs.setBool('vibration_enabled', _vibrationEnabled);
        
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
      backgroundColor: _darkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Preferences
                  _buildSectionHeader('App Preferences'),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications, color: Colors.blue),
                          title: const Text('Push Notifications'),
                          value: _notificationsEnabled,
                          onChanged: (value) => setState(() => _notificationsEnabled = value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.volume_up, color: Colors.green),
                          title: const Text('Sound Effects'),
                          value: _soundEnabled,
                          onChanged: _notificationsEnabled ? (value) => setState(() => _soundEnabled = value) : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.vibration, color: Colors.orange),
                          title: const Text('Haptic Vibration'),
                          value: _vibrationEnabled,
                          onChanged: _notificationsEnabled ? (value) => setState(() => _vibrationEnabled = value) : null,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Information
                  _buildSectionHeader('Information'),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('App Version'),
                          trailing: Text('1.0.2', style: TextStyle(color: Colors.grey)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Privacy Policy'),
                          onTap: () => ToastService.showInfo(context, 'Opening Privacy Policy...'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // System & About
                  _buildSectionHeader('System & About'),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.print, color: Colors.blue),
                          title: const Text('Printer Management'),
                          subtitle: const Text('Configure POS printers and devices'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrinterManagementScreen()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: Colors.green),
                          title: const Text('About App'),
                          subtitle: const Text('Version: 1.0.0 (Dautari Adda POS)'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Dautari Adda',
                              applicationVersion: '1.0.0',
                              applicationIcon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                              children: [
                                const Text("Professional POS & Restaurant Management System."),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required Function(double) onChanged,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.blueAccent),
            title: Text(title),
            trailing: Text(
              '${value.toStringAsFixed(1)}$suffix',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: value,
              min: 0,
              max: 30,
              divisions: 60,
              activeColor: const Color(0xFFFFC107),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
