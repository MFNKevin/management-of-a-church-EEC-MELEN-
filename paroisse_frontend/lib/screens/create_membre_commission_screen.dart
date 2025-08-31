// lib/screens/create_membre_commission_screen.dart

import 'package:flutter/material.dart';
import '../models/commission_financiere_model.dart';
import '../services/commission_financiere_service.dart';

// ** Imports Utilisateur **
import '../models/utilisateur_model.dart';
import '../services/utilisateur_service.dart';

class CreateMembreCommissionScreen extends StatefulWidget {
  final MembreCommission? membre;

  const CreateMembreCommissionScreen({Key? key, this.membre}) : super(key: key);

  @override
  State<CreateMembreCommissionScreen> createState() => _CreateMembreCommissionScreenState();
}

class _CreateMembreCommissionScreenState extends State<CreateMembreCommissionScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedCommissionId;
  int? _utilisateurId;
  String? _role;

  bool get isEditing => widget.membre != null;

  final List<String> rolesPossibles = ['Président', 'Trésorier', 'Secrétaire', 'Membre'];

  List<CommissionFinanciere> commissions = [];
  List<Utilisateur> utilisateurs = [];

  // Services
  final CommissionFinanciereService _service = CommissionFinanciereService();

  @override
  void initState() {
    super.initState();
    _loadCommissions();
    _loadUtilisateurs();
    if (isEditing) {
      _selectedCommissionId = widget.membre!.commissionId;
      _utilisateurId = widget.membre!.utilisateurId;
      _role = widget.membre!.role ?? 'Membre';
    } else {
      _role = 'Membre';
    }
  }

  Future<void> _loadCommissions() async {
    try {
      final data = await _service.fetchCommissions();
      setState(() {
        commissions = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement commissions: $e')),
      );
    }
  }

  Future<void> _loadUtilisateurs() async {
    try {
      final data = await UtilisateurService.fetchUtilisateurs(includeDeleted: false);
      setState(() {
        utilisateurs = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement utilisateurs: $e')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCommissionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une commission')),
      );
      return;
    }
    if (_utilisateurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un utilisateur')),
      );
      return;
    }

    final membre = MembreCommission(
      membreCommissionId: isEditing ? widget.membre!.membreCommissionId : 0,
      commissionId: _selectedCommissionId!,
      utilisateurId: _utilisateurId!,
      role: _role,
    );

    try {
      if (isEditing) {
        await _service.updateMembre(membre);
      } else {
        await _service.createMembre(membre);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Membre mis à jour avec succès' : 'Membre ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 700));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Membre' : 'Ajouter Membre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: (commissions.isEmpty || utilisateurs.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedCommissionId,
                      decoration: const InputDecoration(labelText: 'Commission'),
                      items: commissions.map((c) {
                        return DropdownMenuItem(
                          value: c.commissionId,
                          child: Text(c.nom),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCommissionId = val),
                      validator: (val) => val == null ? 'Champ requis' : null,
                    ),

                    DropdownButtonFormField<int>(
                      value: _utilisateurId,
                      decoration: const InputDecoration(labelText: 'Utilisateur'),
                      items: utilisateurs.map((u) {
                        final fullName = '${u.nom ?? ''} ${u.prenom ?? ''}'.trim();
                        return DropdownMenuItem(
                          value: u.utilisateurId,
                          child: Text(fullName.isNotEmpty ? fullName : 'ID ${u.utilisateurId}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _utilisateurId = val),
                      validator: (val) => val == null ? 'Champ requis' : null,
                    ),

                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: rolesPossibles
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(),
                      onChanged: (val) => setState(() => _role = val),
                      validator: (val) => val == null ? 'Champ requis' : null,
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
