import 'package:flutter/material.dart';

class InfrastructureScreen extends StatelessWidget {
  const InfrastructureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Infrastructures')),
      body: const Center(child: Text('Page des Infrastructures')),
    );
  }
}
