import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecetteGlobalScreen extends StatefulWidget {
  const RecetteGlobalScreen({super.key});

  @override
  State<RecetteGlobalScreen> createState() => _RecetteGlobalScreenState();
}

class _RecetteGlobalScreenState extends State<RecetteGlobalScreen> {
  bool _loading = true;

  double totalDons = 0;
  double totalOffrandes = 0;
  double totalQuetes = 0;
  double totalRecus = 0;

  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: ' FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchTotals();
  }

  Future<void> _fetchTotals() async {
    setState(() {
      _loading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      totalDons = 1250000;
      totalOffrandes = 980000;
      totalQuetes = 450000;
      totalRecus = 320000;
      _loading = false;
    });
  }

  Widget _buildCard({
    required Color color,
    required IconData icon,
    required String title,
    required double amount,
  }) {
    final MaterialColor matColor = color is MaterialColor ? color : Colors.blue;

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: matColor.withOpacity(0.5),
        color: matColor.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: matColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: matColor[700] ?? matColor,
                ),
              ),
              const SizedBox(height: 8),
              _loading
                  ? const CircularProgressIndicator()
                  : Text(
                      currencyFormat.format(amount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: matColor[900] ?? matColor,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord financier'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Résumé des recettes',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacing),
            Row(
              children: [
                _buildCard(
                  color: Colors.blue,
                  icon: Icons.volunteer_activism,
                  title: 'Dons',
                  amount: totalDons,
                ),
                const SizedBox(width: spacing),
                _buildCard(
                  color: Colors.green,
                  icon: Icons.card_giftcard,
                  title: 'Offrandes',
                  amount: totalOffrandes,
                ),
              ],
            ),
            const SizedBox(height: spacing),
            Row(
              children: [
                _buildCard(
                  color: Colors.orange,
                  icon: Icons.attach_money,
                  title: 'Quêtes',
                  amount: totalQuetes,
                ),
                const SizedBox(width: spacing),
                _buildCard(
                  color: Colors.purple,
                  icon: Icons.receipt_long,
                  title: 'Reçus',
                  amount: totalRecus,
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _loading ? null : _fetchTotals,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir les données'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

