import 'package:flutter/material.dart';
import '../models/sous_commission_financiere_model.dart';
import '../services/sous_commission_financiere_service.dart';
import 'create_sous_commission_financiere_screen.dart';
import 'create_membre_sous_commission_screen.dart';

class SousCommissionFinanciereScreen extends StatefulWidget {
  const SousCommissionFinanciereScreen({Key? key}) : super(key: key);

  @override
  State<SousCommissionFinanciereScreen> createState() => _SousCommissionFinanciereScreenState();
}

class _SousCommissionFinanciereScreenState extends State<SousCommissionFinanciereScreen> {
  final SousCommissionFinanciereService service = SousCommissionFinanciereService();

  List<SousCommissionFinanciere>? sousCommissions;
  List<MembreSousCommission>? membres;

  bool afficherSupprimes = false;
  int? filtreSousCommissionId;
  bool isLoading = true;
  String? errorMessage;

  String sousCommissionSearch = '';
  String membreSearch = '';

  int sousCommissionPage = 0;
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
      final fetchedSousCommissions =
          await service.fetchSousCommissions(includeDeleted: afficherSupprimes);
      List<MembreSousCommission> fetchedMembres = [];

      // On ne récupère les membres que si un filtre de sous-commission est sélectionné
      if (filtreSousCommissionId != null) {
        fetchedMembres = await service.fetchMembresBySousCommission(
            filtreSousCommissionId!, includeDeleted: afficherSupprimes);
      }

      setState(() {
        sousCommissions = fetchedSousCommissions;
        membres = fetchedMembres;
        isLoading = false;
        sousCommissionPage = 0;
        membrePage = 0;
      });
    } catch (e) {
      setState(() {
        sousCommissions = null;
        membres = null;
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmDeleteSousCommission(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous supprimer cette sous-commission ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await service.softDeleteSousCommission(id);
        if (filtreSousCommissionId == id) {
          filtreSousCommissionId = null;
        }
        await _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur suppression sous-commission: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur suppression membre: $e')));
      }
    }
  }

  List<SousCommissionFinanciere> get filteredSousCommissions {
    if (sousCommissions == null) return [];
    return sousCommissions!
        .where((c) => c.nom.toLowerCase().contains(sousCommissionSearch.toLowerCase()))
        .toList();
  }

  List<MembreSousCommission> get filteredMembres {
    if (membres == null) return [];
    return membres!.where((m) {
      final nomComplet =
          '${m.nomUtilisateur ?? ""} ${m.prenomUtilisateur ?? ""}'.trim().toLowerCase();
      return nomComplet.contains(membreSearch.toLowerCase()) ||
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
        title: const Text('Sous-Commissions financières'),
        actions: [
          Row(
            children: [
              const Text("Afficher supprimés"),
              Switch(
                value: afficherSupprimes,
                onChanged: (val) {
                  setState(() {
                    afficherSupprimes = val;
                    filtreSousCommissionId = null; // reset filter when toggling deleted
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
                        // Table des sous-commissions
                        _buildTableSection(
                          title: 'Sous-Commissions',
                          searchHint: 'Recherche par nom...',
                          searchValue: sousCommissionSearch,
                          onSearchChanged: (val) => setState(() {
                            sousCommissionSearch = val;
                            sousCommissionPage = 0;
                          }),
                          columns: const [
                            DataColumn(label: Text('Nom')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredSousCommissions.map((sousCommission) {
                            return DataRow(
                              selected: filtreSousCommissionId == sousCommission.sousCommissionId,
                              onSelectChanged: (selected) {
                                setState(() {
                                  filtreSousCommissionId =
                                      selected == true ? sousCommission.sousCommissionId : null;
                                  membreSearch = '';
                                  membrePage = 0;
                                });
                                _fetchData();
                              },
                              cells: [
                                DataCell(Text(sousCommission.nom)),
                                DataCell(Text(sousCommission.description ?? '-')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CreateSousCommissionFinanciereScreen(
                                                sousCommission: sousCommission),
                                          ),
                                        );
                                        _fetchData();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () =>
                                          _confirmDeleteSousCommission(sousCommission.sousCommissionId),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                          currentPage: sousCommissionPage,
                          onPageChange: (next) {
                            setState(() {
                              sousCommissionPage += next ? 1 : -1;
                            });
                          },
                        ),

                        const SizedBox(height: 30),

                        // Bouton d'ajout membre, visible uniquement si une sous-commission est sélectionnée
                        if (filtreSousCommissionId != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.person_add),
                              label: const Text('Ajouter un membre'),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateMembreSousCommissionScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _fetchData();
                                }
                              },
                            ),
                          ),

                        // Table des membres - n'affiche que si filtre activé
                        if (filtreSousCommissionId != null)
                          _buildTableSection(
                            title: 'Membres des Sous-Commissions',
                            searchHint: 'Recherche par nom ou rôle...',
                            searchValue: membreSearch,
                            onSearchChanged: (val) => setState(() {
                              membreSearch = val;
                              membrePage = 0;
                            }),
                            columns: const [
                              DataColumn(label: Text('Nom complet')),
                              DataColumn(label: Text('Rôle')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: filteredMembres.map((membre) {
                              return DataRow(cells: [
                                DataCell(Text(
                                    '${membre.nomUtilisateur ?? '-'} ${membre.prenomUtilisateur ?? ''}'
                                        .trim())),
                                DataCell(Text(membre.role ?? '-')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CreateMembreSousCommissionScreen(membre: membre),
                                          ),
                                        );
                                        _fetchData();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteMembre(membre.membreSousCommissionId),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSousCommissionFinanciereScreen()),
          );
          _fetchData();
        },
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une sous-commission',
      ),
    );
  }
}
