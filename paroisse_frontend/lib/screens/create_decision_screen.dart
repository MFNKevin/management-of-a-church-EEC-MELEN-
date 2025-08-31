import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/decision_model.dart';
import 'package:paroisse_frontend/models/reunion_model.dart';
import 'package:paroisse_frontend/models/utilisateur_model.dart';
import 'package:paroisse_frontend/services/decision_service.dart';
import 'package:paroisse_frontend/services/reunion_service.dart';
import 'package:paroisse_frontend/services/utilisateur_service.dart';
import 'package:paroisse_frontend/constants/roles.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';

class CreateDecisionScreen extends StatefulWidget {
  final Decision? decision;
  final bool initialDetailMode;
  final String? role;

  const CreateDecisionScreen({
    Key? key,
    this.decision,
    this.initialDetailMode = false,
    this.role,
  }) : super(key: key);

  @override
  State<CreateDecisionScreen> createState() => _CreateDecisionScreenState();
}

class _CreateDecisionScreenState extends State<CreateDecisionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;

  DateTime? _dateValide;
  bool _loading = false;

  String? _role;
  int? _utilisateurId;

  List<Reunion> _reunions = [];
  List<Utilisateur> _utilisateurs = [];

  int? _selectedReunionId;
  int? _selectedAuteurId;

  bool get _canEdit {
    if (_role == null) return false;
    final r = _role!.toLowerCase();
    return DecisionRoles.allowed.any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  late bool _isDetailMode;

  @override
  void initState() {
    super.initState();
    _isDetailMode = widget.initialDetailMode;

    _titreController = TextEditingController(text: widget.decision?.titre ?? '');
    _descriptionController = TextEditingController(text: widget.decision?.description ?? '');
    _dateValide = widget.decision?.dateValide;

    _role = widget.role;

    if (_role == null || _utilisateurId == null) {
      _loadUserRoleAndId();
    }

    _loadDropdownData();
  }

  Future<void> _loadUserRoleAndId() async {
    final role = await AuthToken.getUserRole();
    final id = await AuthToken.getUserId();
    setState(() {
      _role = role;
      _utilisateurId = id;
      if (_selectedAuteurId == null) {
        _selectedAuteurId = id;
      }
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      final reunions = await ReunionService.fetchReunions();
      final utilisateurs = await UtilisateurService.fetchUtilisateurs();

      setState(() {
        _reunions = reunions;
        _utilisateurs = utilisateurs;

        if (widget.decision != null) {
          _selectedReunionId = widget.decision!.reunionId;
          _selectedAuteurId = widget.decision!.auteurId;
        } else {
          if (_selectedReunionId == null && _reunions.isNotEmpty) {
            _selectedReunionId = _reunions.first.reunionId;
          }
          if (_selectedAuteurId == null && _utilisateurs.isNotEmpty) {
            _selectedAuteurId = _utilisateurs.first.utilisateurId;
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement données : $e')),
      );
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDecision() async {
    if (!_formKey.currentState!.validate() ||
        _dateValide == null ||
        _selectedReunionId == null ||
        _selectedAuteurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final decision = Decision(
        decisionId: widget.decision?.decisionId ?? 0,
        titre: _titreController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        reunionId: _selectedReunionId!,
        auteurId: _selectedAuteurId!,
        dateValide: _dateValide!,
        createdAt: widget.decision?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: widget.decision?.deletedAt,
        titreReunion: _reunions.firstWhere((r) => r.reunionId == _selectedReunionId!).titre,
        nomAuteur: _utilisateurs.firstWhere((u) => u.utilisateurId == _selectedAuteurId!).nom,
        prenomAuteur: _utilisateurs.firstWhere((u) => u.utilisateurId == _selectedAuteurId!).prenom,
      );

      if (widget.decision == null) {
        await DecisionService.createDecision(decision);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Décision créée avec succès')),
        );
      } else {
        await DecisionService.updateDecision(decision);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Décision mise à jour avec succès')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _softDeleteDecision() async {
    if (widget.decision == null) return;

    try {
      await DecisionService.softDeleteDecision(widget.decision!.decisionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Décision archivée')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur archivage : $e')),
      );
    }
  }

  Future<void> _restoreDecision() async {
    if (widget.decision == null) return;

    try {
      await DecisionService.restoreDecision(widget.decision!.decisionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Décision restaurée')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur restauration : $e')),
      );
    }
  }

  Widget _buildDetailView() {
    final decision = widget.decision!;
    final formatter = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          ListTile(title: const Text('Titre'), subtitle: Text(decision.titre)),
          ListTile(title: const Text('Description'), subtitle: Text(decision.description ?? '-')),
          ListTile(title: const Text('Réunion'), subtitle: Text(decision.titreReunion ?? '-')),
          ListTile(
            title: const Text('Auteur'),
            subtitle: Text('${decision.nomAuteur ?? '-'} ${decision.prenomAuteur ?? '-'}'),
          ),
          ListTile(
            title: const Text('Date validité'),
            subtitle: Text(
              decision.dateValide != null ? formatter.format(decision.dateValide!) : '-',
            ),
          ),
          if (decision.deletedAt != null)
            ListTile(
              title: const Text('Archivée le'),
              subtitle: Text(formatter.format(decision.deletedAt!)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decisionExists = widget.decision != null;
    final isDeleted = widget.decision?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          decisionExists
              ? (_isDetailMode
                  ? 'Détail de la Décision'
                  : (isDeleted ? 'Décision Archivées' : 'Modifier Décision'))
              : 'Nouvelle Décision',
        ),
        actions: [
          if (decisionExists)
            IconButton(
              icon: Icon(_isDetailMode ? Icons.edit : Icons.info_outline),
              tooltip: _isDetailMode ? 'Modifier' : 'Voir détails',
              onPressed: () => setState(() => _isDetailMode = !_isDetailMode),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isDetailMode && decisionExists
              ? _buildDetailView()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _titreController,
                          decoration: const InputDecoration(labelText: 'Titre'),
                          validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                          enabled: !isDeleted && _canEdit,
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          enabled: !isDeleted && _canEdit,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedReunionId,
                          decoration: const InputDecoration(labelText: 'Réunion'),
                          items: _reunions
                              .map((reunion) => DropdownMenuItem<int>(
                                    value: reunion.reunionId,
                                    child: Text(reunion.titre),
                                  ))
                              .toList(),
                          onChanged: !isDeleted && _canEdit
                              ? (val) => setState(() => _selectedReunionId = val)
                              : null,
                          validator: (val) => val == null ? 'Veuillez sélectionner une réunion' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedAuteurId,
                          decoration: const InputDecoration(labelText: 'Auteur'),
                          items: _utilisateurs
                              .map((user) => DropdownMenuItem<int>(
                                    value: user.utilisateurId,
                                    child: Text('${user.nom} ${user.prenom}'),
                                  ))
                              .toList(),
                          onChanged: !isDeleted && _canEdit
                              ? (val) => setState(() => _selectedAuteurId = val)
                              : null,
                          validator: (val) => val == null ? 'Veuillez sélectionner un auteur' : null,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(_dateValide == null
                              ? 'Sélectionner la date de validité'
                              : 'Date validité : ${DateFormat('dd/MM/yyyy').format(_dateValide!)}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: !isDeleted && _canEdit
                              ? () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _dateValide ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() => _dateValide = date);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: !isDeleted && _canEdit ? _saveDecision : null,
                          child: Text(decisionExists ? 'Mettre à jour' : 'Enregistrer'),
                        ),
                        if (decisionExists && !isDeleted && _canEdit)
                          TextButton(
                            onPressed: _softDeleteDecision,
                            child: const Text('Archiver', style: TextStyle(color: Colors.red)),
                          ),
                        if (decisionExists && isDeleted && _canEdit)
                          TextButton(
                            onPressed: _restoreDecision,
                            child: const Text('Restaurer', style: TextStyle(color: Colors.green)),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
