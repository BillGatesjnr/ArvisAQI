import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.location_on,
            title: 'Location Settings',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.info,
            title: 'About ARVISAQI',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF142A5E).withValues(alpha: 0.6),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
