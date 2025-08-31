import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/screens/create_decision_screen.dart';
import 'package:paroisse_frontend/models/decision_model.dart';
import 'package:paroisse_frontend/services/decision_service.dart';
import 'package:paroisse_frontend/services/auth_service.dart';

import '../constants/roles.dart';
import '../widgets/paroisse_scaffold.dart';

class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key});

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  late Future<List<Decision>> decisionsFuture;
  List<Decision> allDecisions = [];
  List<Decision> filteredDecisions = [];

  int _currentPage = 0;
  final int _rowsPerPage = 8;
  bool _loading = false;
  String searchQuery = '';

  String? nomComplet;
  String? role;
  String? photo;
  final String baseUrl = 'http://127.0.0.1:8000';

  bool _userLoading = true;
  bool _userError = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDecisions();
  }

  // Charge les données utilisateur (nom, rôle, photo)
  Future<void> _loadUser() async {
    try {
      final userData = await AuthService.getCurrentUser();
      setState(() {
        final prenom = userData['prenom'] ?? '';
        final nom = userData['nom'] ?? '';
        nomComplet = '$prenom $nom';
        role = userData['role'] ?? '';
        photo = userData['photo'];
        _userLoading = false;
        _userError = false;
      });
    } catch (e) {
      setState(() {
        _userError = true;
        _userLoading = false;
      });
    }
  }

  // Charge la liste des décisions avec pagination
  void _loadDecisions() {
    setState(() {
      decisionsFuture = DecisionService.fetchDecisions(
        skip: _currentPage * _rowsPerPage,
        limit: _rowsPerPage,
      );
    });
  }

  // Rafraîchit la liste en repartant de la page 0
  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadDecisions();
  }

  // Vérifie si l'utilisateur a le droit d'accéder aux décisions
  bool hasDecisionAccess() {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return DecisionRoles.allowed.any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  // Ouvre le formulaire de création/modification ou détail d'une décision
  void _openForm({Decision? decision, bool detailMode = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDecisionScreen(
          decision: decision,
          initialDetailMode: detailMode,
          role: role,
        ),
      ),
    );
    if (result == true) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Décision enregistrée avec succès')),
      );
    }
  }

  // Supprime logiquement une décision (archivage)
  Future<void> _softDeleteDecision(int decisionId) async {
    setState(() => _loading = true);
    try {
      await DecisionService.softDeleteDecision(decisionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Décision archivée')),
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

  // Filtre la liste des décisions selon la recherche
  List<Decision> _filterDecisions(List<Decision> decisions) {
    if (searchQuery.isEmpty) return decisions;
    final lowerQuery = searchQuery.toLowerCase();
    return decisions.where((decision) {
      final titre = decision.titre.toLowerCase();
      final desc = (decision.description ?? '').toLowerCase();
      final reunion = (decision.titreReunion ?? '').toLowerCase();
      final auteur = ((decision.nomAuteur ?? '') + ' ' + (decision.prenomAuteur ?? '')).toLowerCase();
      return titre.contains(lowerQuery) ||
          desc.contains(lowerQuery) ||
          reunion.contains(lowerQuery) ||
          auteur.contains(lowerQuery);
    }).toList();
  }

  // Construction du tableau paginé
  Widget _buildPaginatedTable(List<Decision> data) {
    final formatter = DateFormat('dd/MM/yyyy');
    filteredDecisions = _filterDecisions(data);

    final totalItems = filteredDecisions.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    // Ajuste la page courante si elle dépasse le nombre total de pages
    if (_currentPage >= totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPage = totalPages - 1;
        });
      });
    }

    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final pageItems = filteredDecisions.sublist(
      start,
      end > totalItems ? totalItems : end,
    );

    return Column(
      children: [
        // Champ de recherche
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            width: 400,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher par titre, description, réunion ou auteur',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {
                searchQuery = value;
                _currentPage = 0;
              }),
            ),
          ),
        ),

        // Tableau des décisions
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
                constraints: const BoxConstraints(minWidth: 1000),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('N°')),
                    DataColumn(label: Text('Titre')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Réunion')),
                    DataColumn(label: Text('Auteur')),
                    DataColumn(label: Text('Date validité')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final decision = pageItems[index];
                    final numero = start + index + 1;
                    final isDeleted = decision.deletedAt != null;

                    return DataRow(cells: [
                      DataCell(Text(numero.toString())),
                      DataCell(Text(decision.titre)),
                      DataCell(Text(decision.description ?? '-')),
                      DataCell(Text(decision.titreReunion ?? '-')),
                      DataCell(Text('${decision.nomAuteur ?? '-'} ${decision.prenomAuteur ?? '-'}')),
                      DataCell(Text(decision.dateValide != null
                          ? formatter.format(decision.dateValide!)
                          : '-')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            tooltip: 'Détails',
                            icon: const Icon(Icons.info_outline, color: Colors.green),
                            onPressed: _loading ? null : () => _openForm(decision: decision, detailMode: true),
                          ),
                          if (!isDeleted && hasDecisionAccess())
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: _loading ? null : () => _openForm(decision: decision),
                            ),
                          if (!isDeleted && hasDecisionAccess())
                            IconButton(
                              tooltip: 'Archiver',
                              icon: const Icon(Icons.archive, color: Colors.red),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmer l\'archivage'),
                                          content: Text('Archiver la décision "${decision.titre}" ?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Annuler'),
                                              onPressed: () => Navigator.pop(context, false),
                                            ),
                                            TextButton(
                                              child: const Text(
                                                'Archiver',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                              onPressed: () => Navigator.pop(context, true),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await _softDeleteDecision(decision.decisionId);
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

        // Pagination et rafraîchissement
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(width: 30),
            ElevatedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 10),
              const Text(
                'Erreur chargement utilisateur, veuillez vous reconnecter.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Se reconnecter'),
              ),
            ],
          ),
        ),
      );
    }

    return ParoisseScaffold(
      baseUrl: baseUrl,
      nomComplet: nomComplet,
      role: role,
      photo: photo,
      onLogout: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      title: 'Liste des Décisions',
      body: FutureBuilder<List<Decision>>(
        future: decisionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune décision trouvée.'));
          }

          allDecisions = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allDecisions)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasDecisionAccess()
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
