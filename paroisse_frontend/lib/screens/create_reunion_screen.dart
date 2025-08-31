import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/models/reunion_model.dart';
import 'package:paroisse_frontend/services/reunion_service.dart';
import 'package:paroisse_frontend/screens/reunion_detail_screen.dart';
import '../constants/roles.dart';

class CreateReunionScreen extends StatefulWidget {
  final Reunion? reunion; // null = création
  final String? role; // rôle utilisateur pour contrôle d’accès

  const CreateReunionScreen({this.reunion, this.role, Key? key}) : super(key: key);

  @override
  State<CreateReunionScreen> createState() => _CreateReunionScreenState();
}

class _CreateReunionScreenState extends State<CreateReunionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  late TextEditingController _lieuController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late ConvocateurEnum _selectedConvocateur;

  bool _loading = false;

  // Vérifie si l’utilisateur a le droit d’éditer la réunion
  bool get canEdit =>
      widget.role != null &&
      ReunionRoles.allowed
          .map((e) => e.toLowerCase())
          .contains(widget.role!.toLowerCase());

  // Vérifie si l’utilisateur peut archiver/restaurer (admin uniquement)
  bool get canDelete =>
      widget.role != null &&
      widget.role!.toLowerCase() == Roles.administrateur.toLowerCase();

  @override
  void initState() {
    super.initState();

    _titreController = TextEditingController(text: widget.reunion?.titre ?? '');
    _lieuController = TextEditingController(text: widget.reunion?.lieu ?? '');
    _descriptionController =
        TextEditingController(text: widget.reunion?.description ?? '');
    _selectedDate = widget.reunion?.date ?? DateTime.now();
    _selectedConvocateur = widget.reunion?.convocateurRole ?? ConvocateurEnum.Pasteur;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _lieuController.dispose();
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

    final reunion = Reunion(
      reunionId: widget.reunion?.reunionId ?? 0,
      titre: _titreController.text.trim(),
      date: _selectedDate,
      lieu: _lieuController.text.trim().isEmpty ? null : _lieuController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      convocateurRole: _selectedConvocateur,
      convoques: widget.reunion?.convoques ?? <int>[],
      deletedAt: widget.reunion?.deletedAt,
    );

    if (widget.reunion == null) {
      await _performAction(() => ReunionService.createReunion(reunion));
    } else {
      await _performAction(() => ReunionService.updateReunion(reunion));
    }
  }

  Future<void> _softDelete() async {
    if (widget.reunion == null) return;
    await _performAction(() => ReunionService.softDeleteReunion(widget.reunion!.reunionId));
  }

  Future<void> _restore() async {
    if (widget.reunion == null) return;
    await _performAction(() => ReunionService.restoreReunion(widget.reunion!.reunionId));
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.reunion?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reunion == null
              ? 'Ajouter une Réunion'
              : isDeleted
                  ? 'Réunion Archivées'
                  : 'Modifier une Réunion',
        ),
        actions: [
          if (widget.reunion != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Voir détails',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReunionDetailScreen(reunionId: widget.reunion!.reunionId),
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
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && canEdit && !_loading,
              ),
              TextFormField(
                controller: _lieuController,
                decoration: const InputDecoration(labelText: 'Lieu'),
                enabled: !isDeleted && canEdit && !_loading,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                enabled: !isDeleted && canEdit && !_loading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Date : '),
                  Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: (isDeleted || !canEdit || _loading)
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ConvocateurEnum>(
                value: _selectedConvocateur,
                decoration: const InputDecoration(labelText: 'Convocateur'),
                items: ConvocateurEnum.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (isDeleted || !canEdit || _loading)
                    ? null
                    : (val) => setState(() => _selectedConvocateur = val!),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(widget.reunion == null ? 'Enregistrer' : 'Mettre à jour'),
                  onPressed: (isDeleted || !canEdit) ? null : _submit,
                ),
                if (widget.reunion != null && !isDeleted && canDelete)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete),
                    label: const Text('Archiver'),
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
