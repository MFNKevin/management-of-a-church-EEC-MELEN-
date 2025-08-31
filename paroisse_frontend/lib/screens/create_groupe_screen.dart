import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/groupe_model.dart';
import '../services/groupe_service.dart';
import '../constants/roles.dart';

class CreateGroupeScreen extends StatefulWidget {
  final Groupe? groupe; // null = création
  final String? role;

  const CreateGroupeScreen({this.groupe, this.role, Key? key}) : super(key: key);

  @override
  State<CreateGroupeScreen> createState() => _CreateGroupeScreenState();
}

class _CreateGroupeScreenState extends State<CreateGroupeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;

  bool _loading = false;

  bool get _canEdit =>
      widget.role != null &&
      GroupeRoles.allowed.map((r) => r.toLowerCase()).contains(widget.role!.toLowerCase());

  bool get _canDelete => widget.role?.toLowerCase() == Roles.administrateur.toLowerCase();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.groupe?.nom ?? '');
    _descriptionController = TextEditingController(text: widget.groupe?.description ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
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

    final groupe = Groupe(
      groupeId: widget.groupe?.groupeId ?? 0,
      nom: _nomController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: widget.groupe?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      deletedAt: widget.groupe?.deletedAt,
    );

    if (widget.groupe == null) {
      await _performAction(() => GroupeService.createGroupe(groupe));
    } else {
      await _performAction(() => GroupeService.updateGroupe(groupe));
    }
  }

  Future<void> _softDelete() async {
    if (widget.groupe != null) {
      await _performAction(() => GroupeService.softDeleteGroupe(widget.groupe!.groupeId));
    }
  }

  Future<void> _restore() async {
    if (widget.groupe != null) {
      await _performAction(() => GroupeService.restoreGroupe(widget.groupe!.groupeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.groupe?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupe == null
            ? 'Ajouter un Groupe'
            : isDeleted
                ? 'Groupe Supprimé'
                : 'Modifier un Groupe'),
        actions: [
          if (widget.groupe != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Voir les détails',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GroupeDetailScreen(groupeId: widget.groupe!.groupeId),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom du Groupe'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && _canEdit,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optionnelle)'),
                maxLines: 3,
                enabled: !isDeleted && _canEdit,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(widget.groupe == null ? 'Enregistrer' : 'Mettre à jour'),
                  onPressed: (!isDeleted && _canEdit) ? _submit : null,
                ),
                if (widget.groupe != null && !isDeleted && _canDelete)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    onPressed: _softDelete,
                  ),
                if (isDeleted && _canDelete)
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

class GroupeDetailScreen extends StatefulWidget {
  final int groupeId;

  const GroupeDetailScreen({required this.groupeId, Key? key}) : super(key: key);

  @override
  State<GroupeDetailScreen> createState() => _GroupeDetailScreenState();
}

class _GroupeDetailScreenState extends State<GroupeDetailScreen> {
  late final Future<Groupe?> _groupeFuture;

  @override
  void initState() {
    super.initState();
    _groupeFuture = GroupeService.getGroupeById(widget.groupeId);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Détails du Groupe')),
      body: FutureBuilder<Groupe?>(
        future: _groupeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Groupe non trouvé'));
          }

          final groupe = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ListTile(title: const Text('Nom'), subtitle: Text(groupe.nom)),
                ListTile(
                  title: const Text('Description'),
                  subtitle: Text(groupe.description ?? '-'),
                ),
                ListTile(
                  title: const Text('Créé le'),
                  subtitle: Text(formatter.format(groupe.createdAt)),
                ),
                ListTile(
                  title: const Text('Dernière modification'),
                  subtitle: Text(groupe.updatedAt != null
                      ? formatter.format(groupe.updatedAt!)
                      : '-'),
                ),
                if (groupe.deletedAt != null)
                  ListTile(
                    title: const Text('Supprimé le'),
                    subtitle: Text(formatter.format(groupe.deletedAt!)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
