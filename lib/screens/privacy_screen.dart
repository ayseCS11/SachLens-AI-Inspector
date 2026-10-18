import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Widget _item(IconData icon, String title, String body) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How we protect your data')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _item(Icons.phone_android, 'Everything runs on your phone',
              'Every check happens on this device. Your files are never sent to a server.'),
          _item(Icons.person_off, 'No account, no database',
              'There is no sign in and no cloud storage, so there is nothing to leak.'),
          _item(Icons.memory, 'Files stay in memory',
              'Files are read into memory, checked, and dropped. Temporary copies made for text reading are deleted right away.'),
          _item(Icons.share, 'Sharing is your choice',
              'Reports and cleaned photos are created on the phone and leave it only when you tap share.'),
          _item(Icons.flight, 'Try the airplane mode test',
              'Switch on airplane mode and scan a file. The result is the same, because nothing needs the internet.'),
          _item(Icons.balance, 'Honest limits',
              'SachLens gives evidence, not proof. A clean result does not guarantee a file is genuine, and edited or re saved files can hide their origin.'),
        ],
      ),
    );
  }
}