import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/models/reunion_model.dart';
import 'package:paroisse_frontend/screens/create_reunion_screen.dart';
import 'package:paroisse_frontend/screens/reunion_detail_screen.dart';
import 'package:paroisse_frontend/services/reunion_service.dart';
import 'package:paroisse_frontend/widgets/paroisse_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/roles.dart';

class ReunionScreen extends StatefulWidget {
  const ReunionScreen({Key? key}) : super(key: key);

  @override
  State<ReunionScreen> createState() => _ReunionScreenState();
}

class _ReunionScreenState extends State<ReunionScreen> {
  List<Reunion> allReunions = [];
  List<Reunion> filteredReunions = [];

  int _currentPage = 0;
  final int _rowsPerPage = 8;
  bool _loading = false;
  String searchQuery = '';

  String? nomComplet;
  String? role;
  String? photo;

  bool _userLoading = true;
  bool _userError = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadReunions();
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

  Future<void> _loadReunions() async {
    setState(() => _loading = true);
    try {
      final data = await ReunionService.fetchReunions(includeDeleted: false);
      setState(() {
        allReunions = data;
        _applyFilter();
        _currentPage = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement réunions : $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (searchQuery.isEmpty) {
      filteredReunions = allReunions;
    } else {
      final keyword = searchQuery.toLowerCase();
      filteredReunions = allReunions.where((r) {
        final titre = r.titre.toLowerCase();
        final lieu = r.lieu?.toLowerCase() ?? '';
        final desc = r.description?.toLowerCase() ?? '';
        final convRole = r.convocateurRole != null
            ? r.convocateurRole.toString().split('.').last.toLowerCase()
            : '';
        final dateStr = DateFormat('yyyy-MM-dd').format(r.date).toLowerCase();
        return titre.contains(keyword) ||
            lieu.contains(keyword) ||
            desc.contains(keyword) ||
            convRole.contains(keyword) ||
            dateStr.contains(keyword);
      }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _applyFilter();
      _currentPage = 0;
    });
  }

  Future<void> _refresh() async {
    await _loadReunions();
  }

  void _openForm({Reunion? reunion}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReunionScreen(reunion: reunion, role: role),
      ),
    );
    if (result == true) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réunion enregistrée avec succès')),
        );
      }
    }
  }

  Future<void> _softDeleteReunion(int reunionId) async {
    setState(() => _loading = true);
    try {
      await ReunionService.softDeleteReunion(reunionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réunion archivée')),
        );
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  bool hasRole(List<String> allowedRoles) {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return allowedRoles.map((e) => e.toLowerCase()).contains(r);
  }

  String _enumToString(dynamic enumValue) {
    if (enumValue == null) return '-';
    return enumValue.toString().split('.').last;
  }

  Widget _buildPaginatedTable() {
    final formatter = DateFormat('dd/MM/yyyy');

    final totalItems = filteredReunions.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;

    final safeStart = start < totalItems ? start : 0;
    final safeEnd = end > totalItems ? totalItems : end;

    final pageItems = filteredReunions.sublist(safeStart, safeEnd);

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: SizedBox(
              width: 400,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Rechercher...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: _onSearchChanged,
                enabled: !_loading,
              ),
            ),
          ),
        ),
        // Tableau
        Expanded(
          child: AbsorbPointer(
            absorbing: _loading,
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
                    headingRowColor:
                        MaterialStateProperty.all(Colors.blue.shade100),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: const [
                      DataColumn(label: Text('N°')),
                      DataColumn(label: Text('Titre')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Lieu')),
                      DataColumn(label: Text('Convocateur')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List.generate(pageItems.length, (index) {
                      final reunion = pageItems[index];
                      final numero = safeStart + index + 1;
                      final convocateurText = _enumToString(reunion.convocateurRole);

                      return DataRow(cells: [
                        DataCell(Text(numero.toString())),
                        DataCell(Text(reunion.titre)),
                        DataCell(Text(formatter.format(reunion.date))),
                        DataCell(Text(reunion.lieu ?? '-')),
                        DataCell(Text(convocateurText)),
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
                                    builder: (_) =>
                                        ReunionDetailScreen(reunionId: reunion.reunionId),
                                  ),
                                );
                              },
                            ),
                            if (hasRole(ReunionRoles.allowed))
                              IconButton(
                                tooltip: 'Modifier',
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openForm(reunion: reunion),
                              ),
                            if (hasRole(ReunionRoles.allowed))
                              IconButton(
                                tooltip: 'Archiver',
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmer l\'archivage'),
                                      content: Text(
                                          'Archiver la réunion "${reunion.titre}" ?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Annuler'),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text('Archiver',
                                              style: TextStyle(color: Colors.red)),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await _softDeleteReunion(reunion.reunionId);
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
        ),
        const SizedBox(height: 10),
        // Pagination + Refresh
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
      baseUrl: '',
      onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      title: 'Liste des Réunions',
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable()),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: hasRole(ReunionRoles.allowed)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
