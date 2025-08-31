import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/screens/create_facture_screen.dart';
import 'package:paroisse_frontend/models/facture_model.dart';
import 'package:paroisse_frontend/services/facture_service.dart';
import 'package:paroisse_frontend/services/auth_service.dart';

import '../constants/roles.dart';
import '../widgets/paroisse_scaffold.dart';

class FactureScreen extends StatefulWidget {
  const FactureScreen({super.key});

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  late Future<List<Facture>> facturesFuture;
  List<Facture> filteredFactures = [];

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
    _loadFactures();
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

  void _loadFactures() {
    setState(() {
      facturesFuture = FactureService.fetchFactures(
        skip: _currentPage * _rowsPerPage,
        limit: _rowsPerPage,
      );
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadFactures();
  }

  bool hasFactureAccess() {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return FactureRoles.allowed.any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  Future<void> _softDeleteFacture(int factureId) async {
    setState(() => _loading = true);
    try {
      await FactureService.softDeleteFacture(factureId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facture mise dans la corbeille')),
        );
      }
      await _refresh();
    } catch (e) {
      // Affiche l'erreur personnalisée renvoyée depuis le backend
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Facture> _filterFactures(List<Facture> factures) {
    if (searchQuery.isEmpty) return factures;
    return factures.where((facture) {
      final numero = facture.numero.toLowerCase();
      final description = (facture.description ?? '').toLowerCase();
      return numero.contains(searchQuery.toLowerCase()) || description.contains(searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildPaginatedTable(List<Facture> data) {
    final formatter = DateFormat('dd/MM/yyyy');
    filteredFactures = _filterFactures(data);

    final totalItems = filteredFactures.length;
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
    final pageItems = filteredFactures.sublist(
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
                hintText: 'Rechercher par numéro ou description',
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
                constraints: const BoxConstraints(minWidth: 900),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('N°')),
                    DataColumn(label: Text('Numéro')),
                    DataColumn(label: Text('Montant (FCFA)')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final facture = pageItems[index];
                    final numero = start + index + 1;
                    final isDeleted = facture.deletedAt != null;

                    return DataRow(
                      color: isDeleted
                          ? MaterialStateProperty.all(Colors.red.shade50)
                          : null,
                      cells: [
                        DataCell(Text(numero.toString())),
                        DataCell(Text(facture.numero)),
                        DataCell(Text(facture.montant.toStringAsFixed(2))),
                        DataCell(Text(formatter.format(facture.dateFacture))),
                        DataCell(Text(facture.description ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              tooltip: 'Détails',
                              icon: const Icon(Icons.info_outline, color: Colors.green),
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateFactureScreen(
                                            facture: facture,
                                            initialDetailMode: true,
                                            role: role,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            if (!isDeleted && hasFactureAccess())
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
                                            content: const Text('Supprimer cette facture ?'),
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
                                          await _softDeleteFacture(facture.factureId);
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
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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
      onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      title: 'Liste des Factures',
      body: FutureBuilder<List<Facture>>(
        future: facturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur chargement : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune facture trouvée'));
          }
          return _buildPaginatedTable(snapshot.data!);
        },
      ),
      floatingActionButton: null, // pas de bouton d’ajout ici
    );
  }
}
