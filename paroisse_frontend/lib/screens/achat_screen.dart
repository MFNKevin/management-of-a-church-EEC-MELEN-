// achat_screen.dart (corrigé avec décalage du bouton Rafraîchir sur la gauche)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/models/achat_model.dart';
import 'package:paroisse_frontend/screens/create_achat_screen.dart';


import 'package:paroisse_frontend/services/achat_service.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/widgets/paroisse_scaffold.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/roles.dart';

class AchatScreen extends StatefulWidget {
  const AchatScreen({super.key});

  @override
  State<AchatScreen> createState() => _AchatScreenState();
}

class _AchatScreenState extends State<AchatScreen> {
  late Future<List<Achat>> achatsFuture;
  List<Achat> allAchats = [];
  List<Achat> filteredAchats = [];

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
    _loadAchats();
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

  void _loadAchats() {
    setState(() {
      achatsFuture = AchatService.fetchAchats(includeDeleted: false);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadAchats();
  }

  void _openForm({Achat? achat}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAchatScreen(achat: achat, role: role),
      ),
    );
    if (result == true) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achat enregistré avec succès')),
      );
    }
  }

  Future<void> _softDeleteAchat(int achatId) async {
    setState(() => _loading = true);
    try {
      await AchatService.softDeleteAchat(achatId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achat supprimé')),
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

  List<Achat> _filterAchats(List<Achat> achats) {
    if (searchQuery.isEmpty) return achats;
    return achats.where((achat) =>
      achat.libelle.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (achat.fournisseur ?? '').toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  bool hasRole(List<String> allowedRoles) {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return allowedRoles.map((e) => e.toLowerCase()).contains(r);
  }

  Widget _buildPaginatedTable(List<Achat> data) {
    final formatter = DateFormat('dd/MM/yyyy');
    filteredAchats = _filterAchats(data);

    final totalItems = filteredAchats.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final pageItems = filteredAchats.sublist(start, end > totalItems ? totalItems : end);

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
                    hintText: 'Rechercher par libellé ou fournisseur',
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
                    DataColumn(label: Text('Libellé')),
                    DataColumn(label: Text('Montant (FCFA)')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Fournisseur')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final achat = pageItems[index];
                    final numero = start + index + 1;

                    return DataRow(cells: [
                      DataCell(Text(numero.toString())),
                      DataCell(Text(achat.libelle)),
                      DataCell(Text(achat.montant.toStringAsFixed(2))),
                      DataCell(Text(formatter.format(achat.dateAchat))),
                      DataCell(Text(achat.fournisseur ?? '-')),
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
                                  builder: (_) => AchatDetailScreen(achatId: achat.achatId),
                                ),
                              );
                            },
                          ),
                          if (hasRole(AchatRoles.allowed))
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openForm(achat: achat),
                            ),
                          if (hasRole(AchatRoles.allowed))
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmer la suppression'),
                                    content: Text('Supprimer l\'achat "${achat.libelle}" ?'),
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
                                  await _softDeleteAchat(achat.achatId);
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
      nomComplet: nomComplet,
      role: role,
      photo: photo,
      baseUrl: baseUrl,
      onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      title: 'Liste des Achats',
      body: FutureBuilder<List<Achat>>(
        future: achatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun achat trouvé.'));
          }

          allAchats = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allAchats)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasRole(AchatRoles.allowed)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
