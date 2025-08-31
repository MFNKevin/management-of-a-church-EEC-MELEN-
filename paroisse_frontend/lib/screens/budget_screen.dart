import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/screens/create_budget_screen.dart';
import 'package:paroisse_frontend/models/budget_model.dart';
import 'package:paroisse_frontend/services/budget_service.dart';
import 'package:paroisse_frontend/services/auth_service.dart';

import '../constants/roles.dart';
import '../widgets/paroisse_scaffold.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late Future<List<Budget>> budgetsFuture;
  List<Budget> allBudgets = [];
  List<Budget> filteredBudgets = [];

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
    _loadBudgets();
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

  void _loadBudgets() {
    // On récupère "beaucoup" d'éléments et on pagine/filtre en local.
    setState(() {
      budgetsFuture = BudgetService.fetchBudgets(
        skip: 0,
        limit: 10000, // assez grand pour couvrir la plupart des cas
      );
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
      searchQuery = '';
    });
    _loadBudgets();
  }

  bool hasBudgetAccess() {
    if (role == null || role!.isEmpty) return false;
    final r = role!.toLowerCase();
    return BudgetRoles.allowed
        .any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  void _openForm({Budget? budget, bool detailMode = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBudgetScreen(
          budget: budget,
          initialDetailMode: detailMode,
          role: role,
        ),
      ),
    );
    if (result == true) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget enregistré avec succès')),
        );
      }
    }
  }

  Future<void> _softDeleteBudget(int budgetId) async {
    setState(() => _loading = true);
    try {
      await BudgetService.softDeleteBudget(budgetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget supprimé')),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatAmount(double value) {
    // Format 1 234 567,89
    final f = NumberFormat.decimalPattern('fr');
    return f.format(value);
  }

  List<Budget> _filterBudgets(List<Budget> budgets) {
    if (searchQuery.isEmpty) return budgets;
    final q = searchQuery.toLowerCase();
    return budgets.where((budget) {
      final byIntitule = budget.intitule.toLowerCase().contains(q);
      final byCategorie = budget.categorie.toLowerCase().contains(q);
      final bySousCat = budget.sousCategorie.toLowerCase().contains(q);
      final byStatut = (budget.statut?.toLowerCase().contains(q) ?? false);
      final byAnnee = budget.annee.toString().contains(q);
      return byIntitule || byCategorie || bySousCat || byStatut || byAnnee;
    }).toList();
  }

  Widget _buildPaginatedTable(List<Budget> data) {
    final formatterDate = DateFormat('dd/MM/yyyy');
    filteredBudgets = _filterBudgets(data);

    final totalItems = filteredBudgets.length;
    final totalPages =
        totalItems == 0 ? 1 : (totalItems / _rowsPerPage).ceil().clamp(1, 9999);

    if (_currentPage >= totalPages && totalItems > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentPage = totalPages - 1;
        });
      });
    }

    final start = (_currentPage * _rowsPerPage).clamp(0, totalItems);
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, totalItems);
    final pageItems = filteredBudgets.sublist(start, end);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            width: 500,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText:
                    'Rechercher par intitulé, catégorie, sous-catégorie, statut ou année',
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
        if (totalItems == 0)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Aucun résultat.'),
          ),
        if (totalItems > 0)
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
                    headingRowColor:
                        MaterialStateProperty.all(Colors.blue.shade100),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: const [
                      DataColumn(label: Text('N°')),
                      DataColumn(label: Text('Intitulé')),
                      DataColumn(label: Text('Année')),
                      DataColumn(label: Text('Catégorie')),
                      DataColumn(label: Text('Sous-catégorie')),
                      DataColumn(label: Text('Montant Total (FCFA)')),
                      DataColumn(label: Text('Montant Approuvé (FCFA)')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Date Soumission')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: List.generate(pageItems.length, (index) {
                      final budget = pageItems[index];
                      final numero = start + index + 1;
                      final isDeleted = budget.deletedAt != null;

                      return DataRow(cells: [
                        DataCell(Text(numero.toString())),
                        DataCell(Text(budget.intitule)),
                        DataCell(Text(budget.annee.toString())),
                        DataCell(Text(budget.categorie)),
                        DataCell(Text(budget.sousCategorie)),
                        DataCell(Text(_formatAmount(budget.montantTotal))),
                        DataCell(Text(_formatAmount(budget.montantReel))),
                        DataCell(Text(budget.statut ?? 'Proposé')),
                        DataCell(Text(formatterDate.format(budget.dateSoumission))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              tooltip: 'Détails',
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.blue),
                              onPressed: _loading
                                  ? null
                                  : () => _openForm(
                                        budget: budget,
                                        detailMode: true,
                                      ),
                            ),
                            if (!isDeleted && hasBudgetAccess())
                              IconButton(
                                tooltip: 'Modifier',
                                icon:
                                    const Icon(Icons.edit, color: Colors.orange),
                                onPressed: _loading
                                    ? null
                                    : () => _openForm(budget: budget),
                              ),
                            if (!isDeleted && hasBudgetAccess())
                              IconButton(
                                tooltip: 'Supprimer',
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Confirmer la suppression'),
                                            content: Text(
                                                'Supprimer le budget "${budget.intitule}" ?'),
                                            actions: [
                                              TextButton(
                                                child: const Text('Annuler'),
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                              ),
                                              TextButton(
                                                child: const Text(
                                                  'Supprimer',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await _softDeleteBudget(
                                              budget.budgetId);
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
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page ${totalItems == 0 ? 0 : _currentPage + 1} / $totalPages'),
            IconButton(
              tooltip: 'Suivant',
              onPressed:
                  (_currentPage + 1) * _rowsPerPage < totalItems
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
      title: 'Liste des Budgets',
      body: FutureBuilder<List<Budget>>(
        future: budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun budget trouvé.'));
          }

          allBudgets = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(child: _buildPaginatedTable(allBudgets)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: hasBudgetAccess()
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter"),
              onPressed: _loading ? null : () => _openForm(),
            )
          : null,
    );
  }
}
