import 'package:flutter/material.dart';
import '../models/sous_commission_financiere_model.dart';
import '../services/sous_commission_financiere_service.dart';

import '../models/utilisateur_model.dart';
import '../services/utilisateur_service.dart';

class CreateMembreSousCommissionScreen extends StatefulWidget {
  final MembreSousCommission? membre;

  const CreateMembreSousCommissionScreen({Key? key, this.membre}) : super(key: key);

  @override
  State<CreateMembreSousCommissionScreen> createState() => _CreateMembreSousCommissionScreenState();
}

class _CreateMembreSousCommissionScreenState extends State<CreateMembreSousCommissionScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSousCommissionId;
  int? _utilisateurId;
  String? _role;
  bool _isSubmitting = false;

  bool get isEditing => widget.membre != null;

  final List<String> rolesPossibles = ['Président', 'Trésorier', 'Secrétaire', 'Membre'];

  List<SousCommissionFinanciere> sousCommissions = [];
  List<Utilisateur> utilisateurs = [];

  final SousCommissionFinanciereService _service = SousCommissionFinanciereService();

  @override
  void initState() {
    super.initState();
    _loadSousCommissions();
    _loadUtilisateurs();

    if (isEditing) {
      _selectedSousCommissionId = widget.membre!.sousCommissionId;
      _utilisateurId = widget.membre!.utilisateurId;
      _role = widget.membre!.role ?? 'Membre';
    } else {
      _role = 'Membre';
    }
  }

  Future<void> _loadSousCommissions() async {
    try {
      final data = await _service.fetchSousCommissions();
      if (!mounted) return;
      setState(() {
        sousCommissions = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement sous-commissions: $e')),
        );
      }
    }
  }

  Future<void> _loadUtilisateurs() async {
    try {
      // Appel statique correct de la méthode
      final data = await UtilisateurService.fetchUtilisateurs(includeDeleted: false);
      if (!mounted) return;
      setState(() {
        utilisateurs = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement utilisateurs: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final membre = MembreSousCommission(
      membreSousCommissionId: isEditing ? widget.membre!.membreSousCommissionId : 0,
      sousCommissionId: _selectedSousCommissionId!,
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
            content: Text(
              isEditing ? 'Membre mis à jour avec succès' : 'Membre ajouté avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // succès => rafraîchissement liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        child: (sousCommissions.isEmpty || utilisateurs.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedSousCommissionId,
                      decoration: const InputDecoration(labelText: 'Sous-Commission'),
                      items: sousCommissions.map((c) {
                        return DropdownMenuItem(
                          value: c.sousCommissionId,
                          child: Text(c.nom),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSousCommissionId = val),
                      validator: (val) => val == null ? 'Veuillez sélectionner une sous-commission' : null,
                    ),

                    const SizedBox(height: 12),

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
                      validator: (val) => val == null ? 'Veuillez sélectionner un utilisateur' : null,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: rolesPossibles
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(),
                      onChanged: (val) => setState(() => _role = val),
                      validator: (val) => val == null ? 'Veuillez sélectionner un rôle' : null,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
