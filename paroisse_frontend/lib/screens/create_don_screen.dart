import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/don_model.dart';
import 'package:paroisse_frontend/services/don_service.dart';
import 'package:paroisse_frontend/constants/roles.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';

class CreateDonScreen extends StatefulWidget {
  final Don? don;
  final bool initialDetailMode;
  final String? role;

  const CreateDonScreen({
    Key? key,
    this.don,
    this.initialDetailMode = false,
    this.role,
  }) : super(key: key);

  @override
  State<CreateDonScreen> createState() => _CreateDonScreenState();
}

class _CreateDonScreenState extends State<CreateDonScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _donateurController;
  late TextEditingController _montantController;
  late TextEditingController _commentaireController;

  DateTime? _selectedDate;
  bool _loading = false;

  String? _role;
  String? _selectedType;
  int? _utilisateurId;

  bool get _canEdit {
    if (_role == null) return false;
    final r = _role!.toLowerCase();
    return DonRoles.allowed.any((allowedRole) => allowedRole.toLowerCase() == r);
  }

  late bool _isDetailMode;

  @override
  void initState() {
    super.initState();
    _isDetailMode = widget.initialDetailMode;

    _donateurController = TextEditingController(text: widget.don?.donateur ?? '');
    _montantController = TextEditingController(text: widget.don?.montant.toString() ?? '');
    _commentaireController = TextEditingController(text: widget.don?.commentaire ?? '');
    _selectedDate = widget.don?.dateDon;
    _selectedType = widget.don?.type ?? 'espèce'; // valeur par défaut

    _role = widget.role;

    if (_role == null || _utilisateurId == null) {
      _loadUserRoleAndId();
    }
  }

  Future<void> _loadUserRoleAndId() async {
    final role = await AuthToken.getUserRole();
    final id = await AuthToken.getUserId(); // à implémenter
    setState(() {
      _role = role;
      _utilisateurId = id;
    });
  }

  @override
  void dispose() {
    _donateurController.dispose();
    _montantController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _saveDon() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedType == null || _utilisateurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _loading = true);

    final don = Don(
      donId: widget.don?.donId ?? 0, // ignored if creation
      donateur: _donateurController.text,
      montant: double.parse(_montantController.text),
      dateDon: _selectedDate!,
      commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
      type: _selectedType!,
      utilisateurId: _utilisateurId!,
      deletedAt: widget.don?.deletedAt,
      montantTotal: widget.don?.montantTotal,
    );

    try {
      if (widget.don == null) {
        await DonService.createDon(don);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Don créé avec succès')),
        );
      } else {
        await DonService.updateDon(don);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Don mis à jour avec succès')),
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

  Future<void> _softDeleteDon() async {
    if (widget.don == null) return;

    try {
      await DonService.softDeleteDon(widget.don!.donId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Don supprimé')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression : $e')),
      );
    }
  }

  Future<void> _restoreDon() async {
    if (widget.don == null) return;

    try {
      await DonService.restoreDon(widget.don!.donId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Don restauré')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur restauration : $e')),
      );
    }
  }

  Widget _buildDetailView() {
    final don = widget.don!;
    final formatter = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          ListTile(
            title: const Text('Donateur'),
            subtitle: Text(don.donateur),
          ),
          ListTile(
            title: const Text('Montant (FCFA)'),
            subtitle: Text(don.montant.toStringAsFixed(2)),
          ),
          ListTile(
            title: const Text('Type de don'),
            subtitle: Text(don.type),
          ),
          ListTile(
            title: const Text('Date du don'),
            subtitle: Text(formatter.format(don.dateDon)),
          ),
          ListTile(
            title: const Text('Commentaire'),
            subtitle: Text(don.commentaire ?? '-'),
          ),
          if (don.deletedAt != null)
            ListTile(
              title: const Text('Supprimé le'),
              subtitle: Text(formatter.format(don.deletedAt!)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donExists = widget.don != null;
    final isDeleted = widget.don?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(donExists
            ? (_isDetailMode
                ? 'Détail du Don'
                : (isDeleted ? 'Don Supprimé' : 'Modifier Don'))
            : 'Nouveau Don'),
        actions: [
          if (donExists)
            IconButton(
              icon: Icon(_isDetailMode ? Icons.edit : Icons.info_outline),
              tooltip: _isDetailMode ? 'Modifier' : 'Voir détails',
              onPressed: () {
                setState(() {
                  _isDetailMode = !_isDetailMode;
                });
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isDetailMode && donExists
              ? _buildDetailView()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _donateurController,
                          decoration: const InputDecoration(labelText: 'Nom du donateur'),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Champ requis' : null,
                          enabled: !isDeleted && _canEdit,
                        ),
                        TextFormField(
                          controller: _montantController,
                          decoration: const InputDecoration(labelText: 'Montant'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Champ requis';
                            final montant = double.tryParse(value);
                            if (montant == null || montant <= 0) return 'Montant invalide';
                            return null;
                          },
                          enabled: !isDeleted && _canEdit,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'Type de don'),
                          items: const [
                            DropdownMenuItem(value: 'espèce', child: Text('Espèce')),
                            DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                            DropdownMenuItem(value: 'chèque', child: Text('Chèque')),
                          ],
                          onChanged: !isDeleted && _canEdit
                              ? (value) => setState(() => _selectedType = value)
                              : null,
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Champ requis' : null,
                        ),
                        TextFormField(
                          controller: _commentaireController,
                          decoration:
                              const InputDecoration(labelText: 'Commentaire (optionnel)'),
                          enabled: !isDeleted && _canEdit,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(_selectedDate == null
                              ? 'Sélectionner une date'
                              : 'Date : ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: !isDeleted && _canEdit
                              ? () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() => _selectedDate = date);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: (!isDeleted && _canEdit) ? _saveDon : null,
                          child: Text(widget.don == null ? 'Enregistrer' : 'Mettre à jour'),
                        ),
                        if (donExists && !isDeleted && _canEdit)
                          TextButton(
                            onPressed: _softDeleteDon,
                            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ),
                        if (donExists && isDeleted && _canEdit)
                          TextButton(
                            onPressed: _restoreDon,
                            child: const Text('Restaurer', style: TextStyle(color: Colors.green)),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
