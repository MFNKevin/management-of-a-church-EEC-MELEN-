import 'package:flutter/material.dart';

class StockAlertScreen extends StatelessWidget {
  const StockAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matériels')),
      body: const Center(child: Text('Page des matériels')),
    );
  }
}
