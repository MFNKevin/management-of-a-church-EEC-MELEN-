import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/groupe_model.dart';
import '../services/groupe_service.dart';
import '../constants/roles.dart';
import '../widgets/paroisse_scaffold.dart';
import 'create_groupe_screen.dart';

class GroupeScreen extends StatefulWidget {
  const GroupeScreen({super.key});

  @override
  State<GroupeScreen> createState() => _GroupeScreenState();
}

class _GroupeScreenState extends State<GroupeScreen> {
  late Future<List<Groupe>> groupesFuture;
  List<Groupe> allGroupes = [];
  List<Groupe> filteredGroupes = [];

  final int _rowsPerPage = 8;
  int _currentPage = 0;
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
    _loadGroupes();
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
    } catch (_) {
      setState(() {
        _userLoading = false;
        _userError = true;
      });
    }
  }

  void _loadGroupes() {
    setState(() {
      groupesFuture = GroupeService.fetchGroupes(includeDeleted: false);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadGroupes();
  }

  void _openForm({Groupe? groupe}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupeScreen(groupe: groupe, role: role),
      ),
    );
    if (result == true) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe enregistré avec succès')),
      );
    }
  }

  Future<void> _softDeleteGroupe(int groupeId) async {
    setState(() => _loading = true);
    try {
      await GroupeService.softDeleteGroupe(groupeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe supprimé')),
      );
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression : $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  bool hasRole(List<String> allowedRoles) {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return allowedRoles.map((e) => e.toLowerCase()).contains(r);
  }

  List<Groupe> _filterGroupes(List<Groupe> groupes) {
    if (searchQuery.isEmpty) return groupes;
    final query = searchQuery.toLowerCase();
    return groupes.where((groupe) {
      final nom = groupe.nom.toLowerCase();
      final description = groupe.description?.toLowerCase() ?? '';
      return nom.contains(query) || description.contains(query);
    }).toList();
  }

  Widget _buildPaginatedTable(List<Groupe> data) {
    final formatter = DateFormat('dd/MM/yyyy');
    filteredGroupes = _filterGroupes(data);

    final totalItems = filteredGroupes.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final pageItems = filteredGroupes.sublist(start, end > totalItems ? totalItems : end);

    return Column(
      children: [
        // 🔍 Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: SizedBox(
              width: 400,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Rechercher par nom ou description',
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
        // 📊 Tableau paginé
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
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('N°')),
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Créé le')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final groupe = pageItems[index];
                    final numero = start + index + 1;
                    final isDeleted = groupe.deletedAt != null;

                    return DataRow(cells: [
                      DataCell(Text(numero.toString())),
                      DataCell(Text(groupe.nom)),
                      DataCell(Text(groupe.description ?? '-')),
                      DataCell(Text(formatter.format(groupe.createdAt))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton "Détails" supprimé ici

                          if (!isDeleted && hasRole(GroupeRoles.allowed))
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openForm(groupe: groupe),
                            ),
                          if (!isDeleted && hasRole([Roles.administrateur]))
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmer la suppression'),
                                    content: Text('Supprimer le groupe "${groupe.nom}" ?'),
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
                                  await _softDeleteGroupe(groupe.groupeId);
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
        // 📄 Pagination + Rafraîchissement
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
            const SizedBox(width: 80),
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
      nomComplet: nomComplet,
      role: role,
      photo: photo,
      baseUrl: baseUrl,
      onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      title: 'Liste des Groupes',
      body: FutureBuilder<List<Groupe>>(
        future: groupesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun groupe trouvé.'));
          }

          allGroupes = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allGroupes)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasRole(GroupeRoles.allowed)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
