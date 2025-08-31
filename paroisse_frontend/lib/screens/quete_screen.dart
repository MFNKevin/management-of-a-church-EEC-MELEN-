import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/screens/create_quete_screen.dart';
import 'package:paroisse_frontend/models/quete_model.dart';
import 'package:paroisse_frontend/services/quete_service.dart';
import 'package:paroisse_frontend/services/auth_service.dart';

import '../constants/roles.dart';
import '../widgets/paroisse_scaffold.dart';

// ... imports identiques

class QueteScreen extends StatefulWidget {
  const QueteScreen({super.key});

  @override
  State<QueteScreen> createState() => _QueteScreenState();
}

class _QueteScreenState extends State<QueteScreen> {
  late Future<List<Quete>> quetesFuture;
  List<Quete> filteredQuetes = [];

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
    _loadQuetes();
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

  void _loadQuetes() {
    setState(() {
      quetesFuture = QueteService.fetchQuetes(
        skip: _currentPage * _rowsPerPage,
        limit: _rowsPerPage,
      );
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadQuetes();
  }

  bool hasQueteAccess() {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return QueteRoles.allowed.any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  void _openForm({Quete? quete, bool detailMode = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQueteScreen(
          quete: quete,
          initialDetailMode: detailMode,
          role: role,
        ),
      ),
    );
    if (result == true) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quête enregistrée avec succès')),
        );
      }
    }
  }

  Future<void> _softDeleteQuete(int queteId) async {
    setState(() => _loading = true);
    try {
      await QueteService.softDeleteQuete(queteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quête supprimée')),
        );
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Quete> _filterQuetes(List<Quete> quetes) {
    if (searchQuery.isEmpty) return quetes;
    return quetes.where((quete) {
      final libelle = quete.libelle.toLowerCase();
      return libelle.contains(searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildPaginatedTable(List<Quete> data) {
    final formatter = DateFormat('dd/MM/yyyy');
    filteredQuetes = _filterQuetes(data);

    final totalItems = filteredQuetes.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    if (_currentPage >= totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentPage = totalPages - 1;
        });
      });
    }

    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final pageItems = filteredQuetes.sublist(
      start,
      end > totalItems ? totalItems : end,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            width: 400,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher par libellé',
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
                constraints: const BoxConstraints(minWidth: 700),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor:
                      MaterialStateProperty.all(Colors.green.shade100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('N°')),
                    DataColumn(label: Text('Libellé')),
                    DataColumn(label: Text('Montant (FCFA)')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final quete = pageItems[index];
                    final numero = start + index + 1;
                    final isDeleted = quete.deletedAt != null;

                    return DataRow(
                      color: isDeleted
                          ? MaterialStateProperty.all(Colors.red.shade50)
                          : null,
                      cells: [
                        DataCell(Text(numero.toString())),
                        DataCell(Text(quete.libelle)),
                        DataCell(Text(quete.montant.toStringAsFixed(2))),
                        DataCell(Text(formatter.format(quete.dateQuete))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              tooltip: 'Détails',
                              icon: const Icon(Icons.info_outline, color: Colors.green),
                              onPressed: _loading
                                  ? null
                                  : () => _openForm(quete: quete, detailMode: true),
                            ),
                            if (!isDeleted && hasQueteAccess())
                              IconButton(
                                tooltip: 'Modifier',
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: _loading ? null : () => _openForm(quete: quete),
                              ),
                            if (!isDeleted && hasQueteAccess())
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
                                            content: const Text('Supprimer cette quête ?'),
                                            actions: [
                                              TextButton(
                                                child: const Text('Annuler'),
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: const Text(
                                                  'Supprimer',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await _softDeleteQuete(quete.queteId);
                                        }
                                      },
                              ),
                          ],
                        )),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
      title: 'Liste des Quêtes',
      body: FutureBuilder<List<Quete>>(
        future: quetesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur chargement : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune quête trouvée'));
          }
          return _buildPaginatedTable(snapshot.data!);
        },
      ),
      floatingActionButton: hasQueteAccess()
          ? FloatingActionButton(
              tooltip: 'Ajouter une quête',
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
