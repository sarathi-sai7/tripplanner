import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  final String email;

  const SettingsScreen({
    super.key,
    required this.email,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _preferredCurrency = 'USD';
  String _preferredLanguage = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('settings_notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('settings_dark_mode_enabled') ?? false;
      _preferredCurrency = prefs.getString('settings_preferred_currency') ?? 'USD';
      _preferredLanguage = prefs.getString('settings_preferred_language') ?? 'English';
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    _showSnackBar('Notifications ${value ? 'enabled' : 'disabled'}');
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_dark_mode_enabled', value);
    setState(() {
      _darkModeEnabled = value;
    });
    _showSnackBar('Dark mode ${value ? 'enabled' : 'disabled'}');
  }

  Future<void> _setCurrency(String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_preferred_currency', value);
    setState(() {
      _preferredCurrency = value;
    });
    _showSnackBar('Currency set to $value');
  }

  Future<void> _setLanguage(String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_preferred_language', value);
    setState(() {
      _preferredLanguage = value;
    });
    _showSnackBar('Language set to $value');
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all settings keys except profile-specific keys if any
    final profileImage = prefs.getString('profile_image');
    final profileName = prefs.getString('name');
    final profilePhone = prefs.getString('phone');
    final profileAge = prefs.getString('age');
    final profileGender = prefs.getString('gender');

    await prefs.clear();

    // Restore profile settings if they existed
    if (profileImage != null) await prefs.setString('profile_image', profileImage);
    if (profileName != null) await prefs.setString('name', profileName);
    if (profilePhone != null) await prefs.setString('phone', profilePhone);
    if (profileAge != null) await prefs.setString('age', profileAge);
    if (profileGender != null) await prefs.setString('gender', profileGender);

    await _loadSettings();
    _showSnackBar('App cache cleared successfully!');
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      _showSnackBar('Error signing out: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A6B5A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A6B5A);
    const surfaceColor = Color(0xFFF0F4F3);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Color(0xFF267A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section Header
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Logged in as',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B8580),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.email.isNotEmpty ? widget.email : 'Guest Traveler',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1F1B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences Group
                  _buildSectionTitle('Preferences'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_active_rounded,
                          title: 'Push Notifications',
                          subtitle: 'Receive updates about your trip plans',
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          primaryColor: primaryColor,
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFE8ECEB)),
                        _buildSwitchTile(
                          icon: Icons.dark_mode_rounded,
                          title: 'Dark Mode',
                          subtitle: 'Reduce eye strain in dark environments',
                          value: _darkModeEnabled,
                          onChanged: _toggleDarkMode,
                          primaryColor: primaryColor,
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFE8ECEB)),
                        _buildDropdownTile<String>(
                          icon: Icons.monetization_on_rounded,
                          title: 'Preferred Currency',
                          subtitle: 'Default currency for trip expenses',
                          value: _preferredCurrency,
                          items: const ['USD', 'EUR', 'INR', 'GBP', 'AUD', 'CAD', 'JPY'],
                          onChanged: _setCurrency,
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFE8ECEB)),
                        _buildDropdownTile<String>(
                          icon: Icons.translate_rounded,
                          title: 'Language',
                          subtitle: 'Preferred application language',
                          value: _preferredLanguage,
                          items: const ['English', 'Spanish', 'French', 'German', 'Hindi', 'Japanese'],
                          onChanged: _setLanguage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data & Maintenance Group
                  _buildSectionTitle('App Maintenance'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.cleaning_services_rounded,
                          title: 'Clear App Cache',
                          subtitle: 'Reset preferences without deleting profile',
                          color: const Color(0xFFE05252),
                          onTap: () => _showConfirmDialog(
                            title: 'Clear Cache',
                            content: 'Are you sure you want to clear your local preferences? This will reset custom currencies, notification settings, and local cache.',
                            confirmLabel: 'Clear',
                            onConfirm: _clearCache,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account & Legal Group
                  _buildSectionTitle('Account'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle: 'Disconnect your travel account',
                          color: const Color(0xFFE05252),
                          onTap: () => _showConfirmDialog(
                            title: 'Sign Out',
                            content: 'Are you sure you want to sign out of Trip Planner?',
                            confirmLabel: 'Sign Out',
                            onConfirm: _handleLogout,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Version Info
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Trip Planner',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B8580),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Version 1.0.0 (Build 12)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8BA29F),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B8580),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primaryColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1F1B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B8580)),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A6B5A).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1A6B5A), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1F1B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B8580)),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0D1F1B),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B8580)),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1F1B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B8580)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B8580)),
      onTap: onTap,
    );
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1F1B)),
          ),
          content: Text(
            content,
            style: const TextStyle(color: Color(0xFF6B8580)),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6B8580), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE05252),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                confirmLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
