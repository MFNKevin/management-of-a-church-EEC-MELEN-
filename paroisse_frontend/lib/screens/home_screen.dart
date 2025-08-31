import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/horizontal_navbar.dart';
import '../widgets/vertical_sidebar.dart';
import '../services/auth_service.dart';
import '../config.dart';  // Ajouté pour utiliser Config.baseUrl

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nomComplet;
  String? role;
  String? photo;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userData = await AuthService.getCurrentUser();
      setState(() {
        final prenom = userData['prenom'] ?? '';
        final nom = userData['nom'] ?? '';
        nomComplet = '$prenom $nom';
        role = userData['role'] ?? '';
        photo = userData['photo'];
        isLoading = false;
      });
    } catch (e) {
      print("Erreur de chargement utilisateur: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');  // Suppression du token lors de la déconnexion
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: VerticalSidebar(
        nom: nomComplet,
        role: role,
        photo: photo,
        baseUrl: Config.baseUrl,  // Utilisation de Config.baseUrl ici aussi
        onLogout: _logout,
      ),
      appBar: HorizontalNavbar(nomComplet: nomComplet),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Erreur lors du chargement des données.",
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Retour à la connexion"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votre rôle : $role',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Répartition des recettes",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(value: 40, title: 'Dons', color: Colors.green),
                              PieChartSectionData(value: 30, title: 'Offrandes', color: Colors.orange),
                              PieChartSectionData(value: 30, title: 'Quêtes', color: Colors.blue),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Recettes mensuelles",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            barGroups: [
                              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 50000, color: Colors.green)]),
                              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 30000, color: Colors.green)]),
                              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 70000, color: Colors.green)]),
                              BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 45000, color: Colors.green)]),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    const months = ['Jan', 'Fév', 'Mars', 'Avr'];
                                    return Text(months[value.toInt()]);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
