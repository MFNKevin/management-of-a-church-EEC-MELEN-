import 'package:flutter/material.dart';

class RapportAdministratifScreen extends StatelessWidget {
  const RapportAdministratifScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matériels')),
      body: const Center(child: Text('Page des matériels')),
    );
  }
}
