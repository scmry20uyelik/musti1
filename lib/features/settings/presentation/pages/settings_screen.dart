import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Bildirimler'),
            subtitle: const Text('Bildirim ayarlarını yönetin'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Koyu Tema'),
            subtitle: const Text('Uygulama temasını değiştirin'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // TODO: Implement theme switching
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Uygulama Dili'),
            subtitle: const Text('Türkçe'),
            onTap: () {
              // TODO: Implement language selection
            },
          ),
        ],
      ),
    );
  }
}
