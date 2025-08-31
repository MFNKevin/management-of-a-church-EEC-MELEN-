import 'package:flutter/material.dart';
import 'package:paroisse_frontend/models/utilisateur_model.dart';
import 'package:paroisse_frontend/screens/create_utilisateur_screen.dart';
import 'package:paroisse_frontend/services/utilisateur_service.dart';
import 'package:paroisse_frontend/widgets/paroisse_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/roles.dart'; // Définir UtilisateurRoles.allowed dans ce fichier

class UtilisateurScreen extends StatefulWidget {
  const UtilisateurScreen({super.key});

  @override
  State<UtilisateurScreen> createState() => _UtilisateurScreenState();
}

class _UtilisateurScreenState extends State<UtilisateurScreen> {
  late Future<List<Utilisateur>> utilisateursFuture;
  List<Utilisateur> allUtilisateurs = [];
  List<Utilisateur> filteredUtilisateurs = [];

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
    _loadUtilisateurs();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      nomComplet = prefs.getString('user_nomComplet');
      role = prefs.getString('user_role');
      photo = prefs.getString('user_photo');
      if (mounted) {
        setState(() {
          _userLoading = false;
          _userError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userLoading = false;
          _userError = true;
        });
      }
    }
  }

  void _loadUtilisateurs() {
    setState(() {
      _loading = true;
      utilisateursFuture = UtilisateurService.fetchUtilisateurs();
    });

    utilisateursFuture.then((users) {
      if (mounted) {
        setState(() {
          allUtilisateurs = users;
          filteredUtilisateurs = _filterUtilisateurs(allUtilisateurs);
          _loading = false;
          _currentPage = 0; // reset page à la charge initiale
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement utilisateurs : $e')),
        );
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _currentPage = 0;
    });
    try {
      final users = await UtilisateurService.fetchUtilisateurs();
      if (mounted) {
        setState(() {
          allUtilisateurs = users;
          filteredUtilisateurs = _filterUtilisateurs(allUtilisateurs);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement utilisateurs : $e')),
        );
      }
    }
  }

  void _openForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateUtilisateurScreen(),
      ),
    );
    if (result == true) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur créé avec succès')),
      );
    }
  }

  Future<void> _deleteUtilisateur(int utilisateurId) async {
    setState(() => _loading = true);
    try {
      await UtilisateurService.softDeleteUtilisateur(utilisateurId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé')),
      );
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Utilisateur> _filterUtilisateurs(List<Utilisateur> utilisateurs) {
    if (searchQuery.isEmpty) return utilisateurs;
    final query = searchQuery.toLowerCase();
    return utilisateurs.where((u) =>
        (u.nom?.toLowerCase().contains(query) ?? false) ||
        (u.prenom?.toLowerCase().contains(query) ?? false) ||
        (u.email?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  bool hasRole(List<String> allowedRoles) {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return allowedRoles.map((e) => e.toLowerCase()).contains(r);
  }

  String _roleToString(Utilisateur utilisateur) {
    return utilisateur.role.toString().split('.').last.replaceAllMapped(
      RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}'
    ).trim();
  }

  Widget _buildPaginatedTable(List<Utilisateur> data) {
    // Appliquer le filtre
    filteredUtilisateurs = _filterUtilisateurs(data);

    final totalItems = filteredUtilisateurs.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    // Gérer les bornes
    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final pageItems = filteredUtilisateurs.sublist(
      start,
      end > totalItems ? totalItems : end,
    );

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
                    hintText: 'Rechercher nom, prénom, email...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _currentPage = 0;
                      filteredUtilisateurs = _filterUtilisateurs(allUtilisateurs);
                    });
                  },
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
                    DataColumn(label: Text('Rôle')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final utilisateur = pageItems[index];
                    final numero = start + index + 1;

                    return DataRow(cells: [
                      DataCell(Text(numero.toString())),
                      DataCell(Text(utilisateur.nom ?? '-')),
                      DataCell(Text(utilisateur.prenom ?? '-')),
                      DataCell(Text(utilisateur.email ?? '-')),
                      DataCell(Text(_roleToString(utilisateur))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Détails',
                            icon: const Icon(Icons.info, color: Colors.green),
                            onPressed: () {
                              // TODO: Afficher les détails utilisateur
                            },
                          ),
                          if (hasRole(UtilisateurRoles.allowed))
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmer la suppression'),
                                          content: Text('Supprimer l\'utilisateur ${utilisateur.nom} ?'),
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
                                        await _deleteUtilisateur(utilisateur.utilisateurId);
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
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
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
      title: 'Liste des Utilisateurs',
      body: FutureBuilder<List<Utilisateur>>(
        future: utilisateursFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé.'));
          }

          // On affiche la table à partir de la liste chargée en mémoire
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allUtilisateurs)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasRole(UtilisateurRoles.allowed)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : _openForm,
            )
          : null,
    );
  }
}
