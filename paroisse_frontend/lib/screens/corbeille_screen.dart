import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:paroisse_frontend/models/achat_model.dart';
import 'package:paroisse_frontend/models/don_model.dart';
import 'package:paroisse_frontend/models/offrande_model.dart';
import 'package:paroisse_frontend/models/quete_model.dart';
import 'package:paroisse_frontend/models/recu_model.dart';
import 'package:paroisse_frontend/models/employe_model.dart';

import 'package:paroisse_frontend/utils/auth_token.dart';
import '../config.dart';

class CorbeilleScreen extends StatefulWidget {
  const CorbeilleScreen({super.key});

  @override
  State<CorbeilleScreen> createState() => _CorbeilleScreenState();
}

class _CorbeilleScreenState extends State<CorbeilleScreen> {
  // ====================== VARIABLES ======================
  late Future<List<Achat>> _achatsSupprimes = Future.value([]);
  late Future<List<Don>> _donsSupprimes = Future.value([]);
  late Future<List<Offrande>> _offrandesSupprimees = Future.value([]);
  late Future<List<Quete>> _quetesSupprimees = Future.value([]);
  late Future<List<Recu>> _recusSupprimees = Future.value([]);
  late Future<List<Employe>> _employesSupprimes = Future.value([]);


  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _achatsSupprimes = fetchAchatsSupprimes();
      _donsSupprimes = fetchDonsSupprimes();
      _offrandesSupprimees = fetchOffrandesSupprimees();
      _quetesSupprimees = fetchQuetesSupprimees();
      _recusSupprimees = fetchRecusSupprimes();
      _employesSupprimes = fetchEmployesSupprimes();
    });
  }

  // ====================== SECTION ACHATS ======================
  Future<List<Achat>> fetchAchatsSupprimes() async {
    final token = await AuthToken.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/achats?include_deleted=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Achat.fromJson(e)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> _restoreAchat(int achatId, String libelle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer l\'achat'),
        content: Text('Voulez-vous vraiment restaurer l\'achat "$libelle" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final token = await AuthToken.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/achats/restore/$achatId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Achat restauré avec succès')));
        _loadData();
      } else {
        throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ====================== SECTION DONS ======================
  Future<List<Don>> fetchDonsSupprimes() async {
    final token = await AuthToken.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/dons?include_deleted=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Don.fromJson(e)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> _restoreDon(int donId, String donateur) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer le don'),
        content: Text('Voulez-vous vraiment restaurer le don de "$donateur" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final token = await AuthToken.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/dons/restore/$donId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Don restauré avec succès')));
        _loadData();
      } else {
        throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ====================== SECTION OFFRANDES ======================
  Future<List<Offrande>> fetchOffrandesSupprimees() async {
    final token = await AuthToken.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/offrandes?include_deleted=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Offrande.fromJson(e)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> _restoreOffrande(int offrandeId, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer l\'offrande'),
        content: Text('Voulez-vous vraiment restaurer l\'offrande de type "$type" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final token = await AuthToken.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/offrandes/restore/$offrandeId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offrande restaurée avec succès')));
        _loadData();
      } else {
        throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ====================== SECTION QUETES ======================
  Future<List<Quete>> fetchQuetesSupprimees() async {
    final token = await AuthToken.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/quetes?include_deleted=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Quete.fromJson(e)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> _restoreQuete(int queteId, String libelle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer la quête'),
        content: Text('Voulez-vous vraiment restaurer la quête "$libelle" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final token = await AuthToken.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/quetes/restore/$queteId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quête restaurée avec succès')));
        _loadData();
      } else {
        throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }


// ====================== SECTION EMPLOYES ======================
  Future<List<Employe>> fetchEmployesSupprimes() async {
    final token = await AuthToken.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/employes?include_deleted=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Employe.fromJson(e)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> _restoreEmploye(int employeId, String nom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer l\'employé'),
        content: Text('Voulez-vous vraiment restaurer l\'employé "$nom" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final token = await AuthToken.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/employes/restore/$employeId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employé restauré avec succès')));
        _loadData(); // recharge la liste des employés
      } else {
        throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }


  // ====================== SECTION REÇUS ======================
  Future<List<Recu>> fetchRecusSupprimes() async {
    final token = await AuthToken.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/recus?include_deleted=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Recu.fromJson(e)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> _restoreRecu(int recuId, String numero) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer le reçu'),
        content: Text('Voulez-vous vraiment restaurer le reçu numéro "$numero" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final token = await AuthToken.getToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/recus/restore/$recuId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reçu restauré avec succès')));
        _loadRecus();
      } else {
        throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // Chargement des reçus (méthode appelée après restauration)
  void _loadRecus() {
    setState(() {
      _recusSupprimees = fetchRecusSupprimes();
    });
  }

  // ====================== BUILD UI ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Corbeille globale")),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======== AFFICHAGE DES ACHATS SUPPRIMÉS ========
              FutureBuilder<List<Achat>>(
                future: _achatsSupprimes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur chargement achats supprimés : ${snapshot.error}');
                  }
                  final deletedAchats = snapshot.data?.where((achat) => achat.deletedAt != null).toList() ?? [];
                  if (deletedAchats.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun achat supprimé.'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Achats supprimés", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deletedAchats.length,
                        itemBuilder: (context, index) {
                          final achat = deletedAchats[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(achat.libelle),
                              subtitle: Text('Montant : ${achat.montant.toStringAsFixed(2)} FCFA'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restaurer',
                                onPressed: _loading ? null : () => _restoreAchat(achat.achatId, achat.libelle),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // ======== AFFICHAGE DES DONS SUPPRIMÉS ========
              FutureBuilder<List<Don>>(
                future: _donsSupprimes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur chargement dons supprimés : ${snapshot.error}');
                  }
                  final deletedDons = snapshot.data?.where((don) => don.deletedAt != null).toList() ?? [];
                  if (deletedDons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun don supprimé.'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Dons supprimés", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deletedDons.length,
                        itemBuilder: (context, index) {
                          final don = deletedDons[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(don.donateur),
                              subtitle: Text('Montant : ${don.montant.toStringAsFixed(2)} FCFA'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restaurer',
                                onPressed: _loading ? null : () => _restoreDon(don.donId, don.donateur),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // ======== AFFICHAGE DES OFFRANDES SUPPRIMÉES ========
              FutureBuilder<List<Offrande>>(
                future: _offrandesSupprimees,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur chargement offrandes supprimées : ${snapshot.error}');
                  }
                  final deletedOffrandes = snapshot.data?.where((o) => o.deletedAt != null).toList() ?? [];
                  if (deletedOffrandes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune offrande supprimée.'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Offrandes supprimées", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deletedOffrandes.length,
                        itemBuilder: (context, index) {
                          final offrande = deletedOffrandes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(offrande.type),
                              subtitle: Text('Montant : ${offrande.montant.toStringAsFixed(2)} FCFA'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restaurer',
                                onPressed: _loading ? null : () => _restoreOffrande(offrande.offrandeId, offrande.type),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // ======== AFFICHAGE DES QUÊTES SUPPRIMÉES ========
              FutureBuilder<List<Quete>>(
                future: _quetesSupprimees,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur chargement des quêtes supprimées : ${snapshot.error}');
                  }

                  final deletedQuetes = snapshot.data?.where((q) => q.deletedAt != null).toList() ?? [];

                  if (deletedQuetes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune quête supprimée.'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Quêtes supprimées", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deletedQuetes.length,
                        itemBuilder: (context, index) {
                          final quete = deletedQuetes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(quete.libelle),
                              subtitle: Text('Montant : ${quete.montant.toStringAsFixed(2)} FCFA'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restaurer',
                                onPressed: _loading ? null : () => _restoreQuete(quete.queteId, quete.libelle),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // ======== AFFICHAGE DES REÇUS SUPPRIMÉS ========
              FutureBuilder<List<Recu>>(
                future: _recusSupprimees,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur chargement des reçus supprimés : ${snapshot.error}');
                  }

                  final deletedRecus = snapshot.data?.where((r) => r.deletedAt != null).toList() ?? [];

                  if (deletedRecus.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun reçu supprimé.'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Reçus supprimés", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),                     
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deletedRecus.length,
                        itemBuilder: (context, index) {
                          final recu = deletedRecus[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('Reçu N° ${recu.recuId}'),
                              subtitle: Text('Montant : ${recu.montant.toStringAsFixed(2)} FCFA'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restaurer',
                                onPressed: _loading ? null : () => _restoreRecu(recu.recuId, recu.recuId.toString()),
                              ),
                            ),
                          );
                        },
                      ),

                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // ======== AFFICHAGE DES EMPLOYES SUPPRIMÉS ========
              FutureBuilder<List<Employe>>(
                future: _employesSupprimes,  // Assure-toi d’avoir ce Future<List<Employe>> dans ton State
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur chargement des employés supprimés : ${snapshot.error}');
                  }

                  final deletedEmployes = snapshot.data?.where((e) => e.deletedAt != null).toList() ?? [];

                  if (deletedEmployes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun employé supprimé.'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Employés supprimés", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),                     
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deletedEmployes.length,
                        itemBuilder: (context, index) {
                          final employe = deletedEmployes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('${employe.nom} ${employe.prenom ?? ''}'),
                              subtitle: Text('Poste : ${employe.poste ?? '-'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'Restaurer',
                                onPressed: _loading ? null : () => _restoreEmploye(employe.employeId, employe.nom),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}
