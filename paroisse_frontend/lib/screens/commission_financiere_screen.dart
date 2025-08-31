import 'package:flutter/material.dart';
import '../models/commission_financiere_model.dart';
import '../services/commission_financiere_service.dart';
import 'create_commission_financiere_screen.dart';
import 'create_membre_commission_screen.dart';

class CommissionFinanciereScreen extends StatefulWidget {
  const CommissionFinanciereScreen({Key? key}) : super(key: key);

  @override
  State<CommissionFinanciereScreen> createState() => _CommissionFinanciereScreenState();
}

class _CommissionFinanciereScreenState extends State<CommissionFinanciereScreen> {
  final CommissionFinanciereService service = CommissionFinanciereService();

  List<CommissionFinanciere>? commissions;
  List<MembreCommission>? membres;

  bool afficherSupprimes = false;
  int? filtreCommissionId;
  bool isLoading = true;
  String? errorMessage;

  String commissionSearch = '';
  String membreSearch = '';

  // Pagination
  int commissionPage = 0;
  int membrePage = 0;
  final int rowsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedCommissions = await service.fetchCommissions(includeDeleted: afficherSupprimes);
      List<MembreCommission> fetchedMembres;

      if (filtreCommissionId != null) {
        fetchedMembres = await service.fetchMembresByCommission(filtreCommissionId!, includeDeleted: afficherSupprimes);
      } else {
        fetchedMembres = await service.fetchMembres(includeDeleted: afficherSupprimes);
      }

      setState(() {
        commissions = fetchedCommissions;
        membres = fetchedMembres;
        isLoading = false;
        commissionPage = 0;
        membrePage = 0;
      });
    } catch (e) {
      setState(() {
        commissions = null;
        membres = null;
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmDeleteCommission(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous supprimer cette commission ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await service.softDeleteCommission(id);
        await _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression commission: $e')));
      }
    }
  }

  Future<void> _confirmDeleteMembre(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous supprimer ce membre ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await service.softDeleteMembre(id);
        await _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression membre: $e')));
      }
    }
  }

  List<CommissionFinanciere> get filteredCommissions {
    if (commissions == null) return [];
    return commissions!
        .where((c) => c.nom.toLowerCase().contains(commissionSearch.toLowerCase()))
        .toList();
  }

  List<MembreCommission> get filteredMembres {
    if (membres == null) return [];
    return membres!.where((m) {
      final nom = '${m.nomUtilisateur ?? ""} ${m.prenomUtilisateur ?? ""}'.toLowerCase();
      return nom.contains(membreSearch.toLowerCase()) ||
          (m.nomCommission ?? '').toLowerCase().contains(membreSearch.toLowerCase()) ||
          (m.role ?? '').toLowerCase().contains(membreSearch.toLowerCase());
    }).toList();
  }

  List<DataRow> _paginateRows(List<DataRow> rows, int page) {
    int start = page * rowsPerPage;
    int end = start + rowsPerPage;
    end = end > rows.length ? rows.length : end;
    return rows.sublist(start, end);
  }

  Widget _buildTableSection({
    required String title,
    required String searchHint,
    required String searchValue,
    required void Function(String) onSearchChanged,
    required List<DataColumn> columns,
    required List<DataRow> rows,
    required int currentPage,
    required void Function(bool) onPageChange,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: searchHint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: columns, rows: _paginateRows(rows, currentPage)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 0 ? () => onPageChange(false) : null,
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                    Text('${currentPage + 1} / ${(rows.length / rowsPerPage).ceil()}'),
                    IconButton(
                      onPressed: (currentPage + 1) * rowsPerPage < rows.length
                          ? () => onPageChange(true)
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissions financières'),
        actions: [
          Row(
            children: [
              const Text("Afficher supprimés"),
              Switch(
                value: afficherSupprimes,
                onChanged: (val) {
                  setState(() {
                    afficherSupprimes = val;
                  });
                  _fetchData();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Erreur chargement : $errorMessage'))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    child: Column(
                      children: [
                        _buildTableSection(
                          title: 'Commissions',
                          searchHint: 'Recherche par nom...',
                          searchValue: commissionSearch,
                          onSearchChanged: (val) => setState(() {
                            commissionSearch = val;
                            commissionPage = 0;
                          }),
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredCommissions.map((commission) {
                            return DataRow(cells: [
                              DataCell(Text(commission.nom)),
                              DataCell(Text(commission.description ?? '-')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateCommissionFinanciereScreen(commission: commission),
                                        ),
                                      );
                                      _fetchData();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _confirmDeleteCommission(commission.commissionId),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                          currentPage: commissionPage,
                          onPageChange: (next) {
                            setState(() {
                              commissionPage += next ? 1 : -1;
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildTableSection(
                          title: 'Membres de commissions',
                          searchHint: 'Recherche par nom, rôle ou commission...',
                          searchValue: membreSearch,
                          onSearchChanged: (val) => setState(() {
                            membreSearch = val;
                            membrePage = 0;
                          }),
                          columns: const [
                            DataColumn(label: Text('Nom complet')),
                            DataColumn(label: Text('Commission')),
                            DataColumn(label: Text('Rôle')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredMembres.map((membre) {
                            final nomComplet = '${membre.nomUtilisateur ?? ""} ${membre.prenomUtilisateur ?? ""}'.trim();
                            return DataRow(cells: [
                              DataCell(Text(nomComplet)),
                              DataCell(Text(membre.nomCommission ?? '-')),
                              DataCell(Text(membre.role ?? 'Membre')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateMembreCommissionScreen(membre: membre),
                                        ),
                                      );
                                      _fetchData();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _confirmDeleteMembre(membre.membreCommissionId),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                          currentPage: membrePage,
                          onPageChange: (next) {
                            setState(() {
                              membrePage += next ? 1 : -1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_commission',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateCommissionFinanciereScreen()),
              );
              _fetchData();
            },
            tooltip: 'Ajouter Commission',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_membre',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateMembreCommissionScreen()),
              );
              _fetchData();
            },
            tooltip: 'Ajouter Membre',
            child: const Icon(Icons.person_add),
          ),
        ],
      ),
    );
  }
}
