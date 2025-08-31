import 'package:flutter/material.dart';
import 'package:paroisse_frontend/models/inspecteur_model.dart';
import 'package:paroisse_frontend/services/inspecteur_service.dart';
import 'package:intl/intl.dart';

import '../constants/roles.dart';

// === CREATE INSPECTEUR SCREEN ===

class CreateInspecteurScreen extends StatefulWidget {
  final Inspecteur? inspecteur; // null = création
  final String? role; // rôle utilisateur pour contrôle d’accès

  const CreateInspecteurScreen({this.inspecteur, this.role, Key? key}) : super(key: key);

  @override
  State<CreateInspecteurScreen> createState() => _CreateInspecteurScreenState();
}

class _CreateInspecteurScreenState extends State<CreateInspecteurScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _fonctionController;

  bool _loading = false;

  bool get canEdit =>
      widget.role != null &&
      InspecteurRoles.allowed
          .map((e) => e.toLowerCase())
          .contains(widget.role!.toLowerCase());

  bool get canDelete =>
      widget.role != null &&
      widget.role!.toLowerCase() == Roles.administrateur.toLowerCase();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.inspecteur?.nom ?? '');
    _prenomController = TextEditingController(text: widget.inspecteur?.prenom ?? '');
    _emailController = TextEditingController(text: widget.inspecteur?.email ?? '');
    _telephoneController = TextEditingController(text: widget.inspecteur?.telephone ?? '');
    _fonctionController = TextEditingController(text: widget.inspecteur?.fonction ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _fonctionController.dispose();
    super.dispose();
  }

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    final inspecteur = Inspecteur(
      inspecteurId: widget.inspecteur?.inspecteurId ?? 0,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim().isEmpty
          ? null
          : _prenomController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      telephone: _telephoneController.text.trim().isEmpty
          ? null
          : _telephoneController.text.trim(),
      fonction: _fonctionController.text.trim().isEmpty ? null : _fonctionController.text.trim(),
      deletedAt: widget.inspecteur?.deletedAt,
      createdAt: widget.inspecteur?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.inspecteur == null) {
      // Création : toJson() gère les champs
      await _performAction(() => InspecteurService.createInspecteur(inspecteur));
    } else {
      await _performAction(() => InspecteurService.updateInspecteur(inspecteur));
    }
  }

  Future<void> _softDelete() async {
    if (widget.inspecteur == null) return;
    await _performAction(
      () => InspecteurService.softDeleteInspecteur(widget.inspecteur!.inspecteurId),
    );
  }

  Future<void> _restore() async {
    if (widget.inspecteur == null) return;
    await _performAction(
      () => InspecteurService.restoreInspecteur(widget.inspecteur!.inspecteurId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.inspecteur?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inspecteur == null
            ? 'Ajouter un Inspecteur'
            : isDeleted
                ? 'Inspecteur Supprimé'
                : 'Modifier un Inspecteur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: !isDeleted && canEdit,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _fonctionController,
                decoration: const InputDecoration(labelText: 'Fonction'),
                enabled: !isDeleted && canEdit,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(widget.inspecteur == null ? 'Enregistrer' : 'Mettre à jour'),
                  onPressed: (isDeleted || !canEdit) ? null : _submit,
                ),
                if (widget.inspecteur != null && !isDeleted && canDelete)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    onPressed: _softDelete,
                  ),
                if (isDeleted && canDelete)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurer'),
                    onPressed: _restore,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// === INSPECTEUR DETAIL SCREEN ===

class InspecteurDetailScreen extends StatefulWidget {
  final int inspecteurId;

  const InspecteurDetailScreen({required this.inspecteurId, Key? key}) : super(key: key);

  @override
  State<InspecteurDetailScreen> createState() => _InspecteurDetailScreenState();
}

class _InspecteurDetailScreenState extends State<InspecteurDetailScreen> {
  late Future<Inspecteur> inspecteurFuture;

  @override
  void initState() {
    super.initState();
    inspecteurFuture = InspecteurService.getInspecteurById(widget.inspecteurId);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de l\'inspecteur')),
      body: FutureBuilder<Inspecteur>(
        future: inspecteurFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Inspecteur non trouvé'));
          }

          final inspecteur = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Nom'),
                  subtitle: Text(inspecteur.nom),
                ),
                ListTile(
                  title: const Text('Prénom'),
                  subtitle: Text(inspecteur.prenom ?? '-'),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(inspecteur.email ?? '-'),
                ),
                ListTile(
                  title: const Text('Téléphone'),
                  subtitle: Text(inspecteur.telephone ?? '-'),
                ),
                ListTile(
                  title: const Text('Fonction'),
                  subtitle: Text(inspecteur.fonction ?? '-'),
                ),
                ListTile(
                  title: const Text('Créé le'),
                  subtitle: inspecteur.createdAt != null
                      ? Text(formatter.format(inspecteur.createdAt!))
                      : const Text('-'),
                ),
                ListTile(
                  title: const Text('Mis à jour le'),
                  subtitle: inspecteur.updatedAt != null
                      ? Text(formatter.format(inspecteur.updatedAt!))
                      : const Text('-'),
                ),
                if (inspecteur.deletedAt != null)
                  ListTile(
                    title: const Text('Supprimé le'),
                    subtitle: Text(formatter.format(inspecteur.deletedAt!)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
