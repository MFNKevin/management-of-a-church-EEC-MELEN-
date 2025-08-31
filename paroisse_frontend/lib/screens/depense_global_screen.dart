import 'package:flutter/material.dart';

class DepenseGlobalScreen extends StatelessWidget {
  const DepenseGlobalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reunions')),
      body: const Center(child: Text('Page des Reunions')),
    );
  }
}
