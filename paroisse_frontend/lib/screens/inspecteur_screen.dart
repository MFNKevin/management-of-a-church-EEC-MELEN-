import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/models/inspecteur_model.dart';
import 'package:paroisse_frontend/screens/create_inspecteur_screen.dart';

import 'package:paroisse_frontend/services/inspecteur_service.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/widgets/paroisse_scaffold.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/roles.dart';  // InspecteurRoles doit être défini ici

class InspecteurScreen extends StatefulWidget {
  const InspecteurScreen({super.key});

  @override
  State<InspecteurScreen> createState() => _InspecteurScreenState();
}

class _InspecteurScreenState extends State<InspecteurScreen> {
  late Future<List<Inspecteur>> inspecteursFuture;
  List<Inspecteur> allInspecteurs = [];
  List<Inspecteur> filteredInspecteurs = [];

  int _currentPage = 0;
  final int _rowsPerPage = 8;
  bool _loading = false;
  String searchQuery = '';

  String? nomComplet;
  String? role;
  String? photo;

  final String baseUrl = 'http://127.0.0.1:8000';  // obligatoire pour ParoisseScaffold

  bool _userLoading = true;
  bool _userError = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadInspecteurs();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      nomComplet = prefs.getString('user_nomComplet');
      role = prefs.getString('user_role');
      photo = prefs.getString('user_photo');

      setState(() {
        _userLoading = false;
        _userError = false;
      });
    } catch (e) {
      setState(() {
        _userLoading = false;
        _userError = true;
      });
    }
  }

  void _loadInspecteurs() {
    setState(() {
      inspecteursFuture = InspecteurService.fetchInspecteurs(includeDeleted: false);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadInspecteurs();
  }

  void _openForm({Inspecteur? inspecteur}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInspecteurScreen(inspecteur: inspecteur, role: role),
      ),
    );
    if (result == true) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspecteur enregistré avec succès')),
      );
    }
  }

  Future<void> _softDeleteInspecteur(int inspecteurId) async {
    setState(() => _loading = true);
    try {
      await InspecteurService.softDeleteInspecteur(inspecteurId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspecteur supprimé')),
      );
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Inspecteur> _filterInspecteurs(List<Inspecteur> inspecteurs) {
    if (searchQuery.isEmpty) return inspecteurs;
    return inspecteurs.where((inspecteur) =>
      inspecteur.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (inspecteur.prenom ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
      (inspecteur.email ?? '').toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  bool hasRole(List<String> allowedRoles) {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return allowedRoles.map((e) => e.toLowerCase()).contains(r);
  }

  Widget _buildPaginatedTable(List<Inspecteur> data) {
    filteredInspecteurs = _filterInspecteurs(data);

    final totalItems = filteredInspecteurs.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final pageItems = filteredInspecteurs.sublist(start, end > totalItems ? totalItems : end);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: SizedBox(
              width: 400,
              child: Semantics(
                label: 'Champ de recherche',
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Rechercher par nom, prénom ou email',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => setState(() {
                    searchQuery = value;
                    _currentPage = 0;
                  }),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(top: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1100),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('N°')),
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Prénom')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Téléphone')),
                    DataColumn(label: Text('Fonction')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final inspecteur = pageItems[index];
                    final numero = start + index + 1;

                    return DataRow(cells: [
                      DataCell(Text(numero.toString())),
                      DataCell(Text(inspecteur.nom)),
                      DataCell(Text(inspecteur.prenom ?? '-')),
                      DataCell(Text(inspecteur.email ?? '-')),
                      DataCell(Text(inspecteur.telephone ?? '-')),
                      DataCell(Text(inspecteur.fonction ?? '-')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Détails',
                            icon: const Icon(Icons.info, color: Colors.green),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InspecteurDetailScreen(inspecteurId: inspecteur.inspecteurId),
                                ),
                              );
                            },
                          ),

                          if (hasRole(InspecteurRoles.allowed))
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openForm(inspecteur: inspecteur),
                            ),
                          if (hasRole(InspecteurRoles.allowed))
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmer la suppression'),
                                    content: Text('Supprimer l\'inspecteur "${inspecteur.nom}" ?'),
                                    actions: [
                                      TextButton(
                                        child: const Text('Annuler'),
                                        onPressed: () => Navigator.pop(context, false),
                                      ),
                                      TextButton(
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        onPressed: () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await _softDeleteInspecteur(inspecteur.inspecteurId);
                                }
                              },
                            ),
                        ],
                      )),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Précédent',
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${_currentPage + 1} / $totalPages'),
                IconButton(
                  tooltip: 'Suivant',
                  onPressed: (_currentPage + 1) * _rowsPerPage < totalItems
                      ? () => setState(() => _currentPage++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rafraîchir'),
                  onPressed: _loading ? null : _refresh,
                ),
              ],
            ),
            const SizedBox(width: 80), // Pour compenser l'espace du bouton Ajouter à droite
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_userError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Erreur chargement utilisateur, veuillez vous reconnecter.',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return ParoisseScaffold(
      baseUrl: baseUrl, // obligatoire
      nomComplet: nomComplet,
      role: role,
      photo: photo,
      onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      title: 'Liste des Inspecteurs',
      body: FutureBuilder<List<Inspecteur>>(
        future: inspecteursFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun inspecteur trouvé.'));
          }

          allInspecteurs = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allInspecteurs)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasRole(InspecteurRoles.allowed)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
