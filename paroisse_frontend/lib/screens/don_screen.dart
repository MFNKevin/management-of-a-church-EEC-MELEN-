import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/screens/create_don_screen.dart';
import 'package:paroisse_frontend/models/don_model.dart';
import 'package:paroisse_frontend/services/don_service.dart';
import 'package:paroisse_frontend/services/auth_service.dart';

import '../constants/roles.dart';
import '../widgets/paroisse_scaffold.dart';

class DonScreen extends StatefulWidget {
  const DonScreen({super.key});

  @override
  State<DonScreen> createState() => _DonScreenState();
}

class _DonScreenState extends State<DonScreen> {
  late Future<List<Don>> donsFuture;
  List<Don> allDons = [];
  List<Don> filteredDons = [];

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
    _loadDons();
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

  void _loadDons() {
    setState(() {
      donsFuture = DonService.fetchDons(
        skip: _currentPage * _rowsPerPage,
        limit: _rowsPerPage,
      );
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
    });
    _loadDons();
  }

  bool hasDonAccess() {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return DonRoles.allowed.any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  void _openForm({Don? don, bool detailMode = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateDonScreen(don: don, initialDetailMode: detailMode, role: role),
      ),
    );
    if (result == true) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Don enregistré avec succès')),
      );
    }
  }

  Future<void> _softDeleteDon(int donId) async {
    setState(() => _loading = true);
    try {
      await DonService.softDeleteDon(donId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Don supprimé')),
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

  List<Don> _filterDons(List<Don> dons) {
    if (searchQuery.isEmpty) return dons;
    return dons
        .where((don) =>
            don.donateur.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (don.commentaire ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
            don.type.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildPaginatedTable(List<Don> data) {
    final formatter = DateFormat('dd/MM/yyyy');
    filteredDons = _filterDons(data);

    final totalItems = filteredDons.length;
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
    final pageItems = filteredDons.sublist(
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
                hintText: 'Rechercher par donateur, type ou commentaire',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                constraints: const BoxConstraints(minWidth: 1000),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor:
                      MaterialStateProperty.all(Colors.green.shade100),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('N°')),
                    DataColumn(label: Text('Donateur')),
                    DataColumn(label: Text('Montant (FCFA)')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Commentaire')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(pageItems.length, (index) {
                    final don = pageItems[index];
                    final numero = start + index + 1;
                    final isDeleted = don.deletedAt != null;
                    return DataRow(cells: [
                      DataCell(Text(numero.toString())),
                      DataCell(Text(don.donateur)),
                      DataCell(Text(don.montant.toStringAsFixed(2))),
                      DataCell(Text(don.type)),
                      DataCell(Text(formatter.format(don.dateDon))),
                      DataCell(Text(don.commentaire ?? '-')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            tooltip: 'Détails',
                            icon: const Icon(Icons.info_outline, color: Colors.green),
                            onPressed:
                                _loading ? null : () => _openForm(don: don, detailMode: true),
                          ),
                          if (!isDeleted && hasDonAccess())
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: _loading ? null : () => _openForm(don: don),
                            ),
                          if (!isDeleted && hasDonAccess())
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
                                          content: Text('Supprimer le don de "${don.donateur}" ?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Annuler'),
                                              onPressed: () => Navigator.pop(context, false),
                                            ),
                                            TextButton(
                                              child: const Text(
                                                'Supprimer',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                              onPressed: () => Navigator.pop(context, true),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await _softDeleteDon(don.donId);
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
        // Pagination + rafraîchir en bas
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
      title: 'Liste des Dons',
      body: FutureBuilder<List<Don>>(
        future: donsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun don trouvé.'));
          }

          allDons = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allDons)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasDonAccess()
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
