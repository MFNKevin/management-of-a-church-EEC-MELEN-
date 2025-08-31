import 'package:flutter/material.dart';
import 'package:paroisse_frontend/models/achat_model.dart';
import 'package:paroisse_frontend/services/achat_service.dart';
import 'package:intl/intl.dart';

// Import des rôles
import '../constants/roles.dart';

// === CREATE ACHAT SCREEN ===

class CreateAchatScreen extends StatefulWidget {
  final Achat? achat; // null = création
  final String? role; // rôle utilisateur pour contrôle d’accès

  const CreateAchatScreen({this.achat, this.role, Key? key}) : super(key: key);

  @override
  State<CreateAchatScreen> createState() => _CreateAchatScreenState();
}

class _CreateAchatScreenState extends State<CreateAchatScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _libelleController;
  late TextEditingController _montantController;
  late TextEditingController _fournisseurController;
  late DateTime _selectedDate;

  bool _loading = false;

  // Utilisation des rôles de AchatRoles pour contrôle accès
  bool get canEdit =>
      widget.role != null &&
      AchatRoles.allowed.map((e) => e.toLowerCase()).contains(widget.role!.toLowerCase());

  // Droit de suppression/restauration — ici on autorise seulement administrateur
  bool get canDelete =>
      widget.role != null &&
      widget.role!.toLowerCase() == Roles.administrateur.toLowerCase();

  @override
  void initState() {
    super.initState();
    _libelleController = TextEditingController(text: widget.achat?.libelle ?? '');
    _montantController = TextEditingController(
      text: widget.achat != null ? widget.achat!.montant.toString() : '',
    );
    _fournisseurController = TextEditingController(text: widget.achat?.fournisseur ?? '');
    _selectedDate = widget.achat?.dateAchat ?? DateTime.now();
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _montantController.dispose();
    _fournisseurController.dispose();
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

    final achat = Achat(
      achatId: widget.achat?.achatId ?? 0,
      libelle: _libelleController.text.trim(),
      montant: double.parse(_montantController.text.trim()),
      dateAchat: _selectedDate,
      fournisseur: _fournisseurController.text.trim(),
      deletedAt: widget.achat?.deletedAt,
    );

    if (widget.achat == null) {
      await _performAction(() => AchatService.createAchat(achat));
    } else {
      await _performAction(() => AchatService.updateAchat(achat));
    }
  }

  Future<void> _softDelete() async {
    if (widget.achat == null) return;
    await _performAction(() => AchatService.softDeleteAchat(widget.achat!.achatId));
  }

  Future<void> _restore() async {
    if (widget.achat == null) return;
    await _performAction(() => AchatService.restoreAchat(widget.achat!.achatId));
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.achat?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.achat == null
            ? 'Ajouter un Achat'
            : isDeleted
                ? 'Achat Supprimé'
                : 'Modifier un Achat'),
        actions: [
          if (widget.achat != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Voir détails',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AchatDetailScreen(achatId: widget.achat!.achatId),
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
                controller: _libelleController,
                decoration: const InputDecoration(labelText: 'Libellé'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                validator: (value) {
                  if (value == null || double.tryParse(value.trim()) == null) {
                    return 'Montant invalide';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _fournisseurController,
                decoration: const InputDecoration(labelText: 'Fournisseur'),
                enabled: !isDeleted && canEdit,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Date : '),
                  Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: (isDeleted || !canEdit)
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
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(widget.achat == null ? 'Enregistrer' : 'Mettre à jour'),
                  onPressed: (isDeleted || !canEdit) ? null : _submit,
                ),
                if (widget.achat != null && !isDeleted && canDelete)
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

// === ACHAT DETAIL SCREEN ===

class AchatDetailScreen extends StatefulWidget {
  final int achatId;

  const AchatDetailScreen({required this.achatId, Key? key}) : super(key: key);

  @override
  State<AchatDetailScreen> createState() => _AchatDetailScreenState();
}

class _AchatDetailScreenState extends State<AchatDetailScreen> {
  late Future<Achat> achatFuture;

  @override
  void initState() {
    super.initState();
    achatFuture = AchatService.getAchatById(widget.achatId);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'achat')),
      body: FutureBuilder<Achat>(
        future: achatFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Achat non trouvé'));
          }

          final achat = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ListTile(title: const Text('Libellé'), subtitle: Text(achat.libelle)),
                ListTile(
                  title: const Text('Montant (FCFA)'),
                  subtitle: Text(achat.montant.toStringAsFixed(2)),
                ),
                ListTile(
                  title: const Text('Date d\'achat'),
                  subtitle: Text(formatter.format(achat.dateAchat)),
                ),
                ListTile(
                  title: const Text('Fournisseur'),
                  subtitle: Text(achat.fournisseur ?? '-'),
                ),
                if (achat.deletedAt != null)
                  ListTile(
                    title: const Text('Supprimé le'),
                    subtitle: Text(formatter.format(achat.deletedAt!)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
