import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/employe_model.dart';
import 'package:paroisse_frontend/services/employe_service.dart';
import '../constants/roles.dart';

class CreateEmployeScreen extends StatefulWidget {
  final Employe? employe;
  final String? role;

  const CreateEmployeScreen({this.employe, this.role, Key? key}) : super(key: key);

  @override
  State<CreateEmployeScreen> createState() => _CreateEmployeScreenState();
}

class _CreateEmployeScreenState extends State<CreateEmployeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _posteController;
  late TextEditingController _salaireController;

  bool _loading = false;

  bool get canEdit =>
      widget.role != null &&
      EmployeRoles.allowed.map((e) => e.toLowerCase()).contains(widget.role!.toLowerCase());

  bool get canDelete =>
      widget.role != null &&
      widget.role!.toLowerCase() == Roles.administrateur.toLowerCase();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.employe?.nom ?? '');
    _prenomController = TextEditingController(text: widget.employe?.prenom ?? '');
    _posteController = TextEditingController(text: widget.employe?.poste ?? '');
    _salaireController = TextEditingController(
      text: widget.employe != null ? widget.employe!.salaire.toString() : '',
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _posteController.dispose();
    _salaireController.dispose();
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

    final employe = Employe(
      employeId: widget.employe?.employeId ?? 0,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      poste: _posteController.text.trim(),
      salaire: double.parse(_salaireController.text.trim()),
      deletedAt: widget.employe?.deletedAt,
    );

    if (widget.employe == null) {
      await _performAction(() => EmployeService.createEmploye(employe));
    } else {
      await _performAction(() => EmployeService.updateEmploye(employe));
    }
  }

  Future<void> _softDelete() async {
    if (widget.employe == null) return;
    await _performAction(() => EmployeService.softDeleteEmploye(widget.employe!.employeId));
  }

  Future<void> _restore() async {
    if (widget.employe == null) return;
    await _performAction(() => EmployeService.restoreEmploye(widget.employe!.employeId));
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.employe?.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employe == null
            ? 'Ajouter un Employé'
            : isDeleted
                ? 'Employé Supprimé'
                : 'Modifier un Employé'),
        actions: [
          if (widget.employe != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Voir détails',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EmployeDetailScreen(employeId: widget.employe!.employeId),
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
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _posteController,
                decoration: const InputDecoration(labelText: 'Poste'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Champ requis' : null,
                enabled: !isDeleted && canEdit,
              ),
              TextFormField(
                controller: _salaireController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Salaire (FCFA)'),
                validator: (value) {
                  if (value == null || double.tryParse(value.trim()) == null) {
                    return 'Salaire invalide';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'Le salaire doit être supérieur à 0';
                  }
                  return null;
                },
                enabled: !isDeleted && canEdit,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(widget.employe == null ? 'Enregistrer' : 'Mettre à jour'),
                  onPressed: (isDeleted || !canEdit) ? null : _submit,
                ),
                if (widget.employe != null && !isDeleted && canDelete)
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

// === EMPLOYE DETAIL SCREEN ===

class EmployeDetailScreen extends StatefulWidget {
  final int employeId;

  const EmployeDetailScreen({required this.employeId, Key? key}) : super(key: key);

  @override
  State<EmployeDetailScreen> createState() => _EmployeDetailScreenState();
}

class _EmployeDetailScreenState extends State<EmployeDetailScreen> {
  late Future<Employe> employeFuture;

  @override
  void initState() {
    super.initState();
    employeFuture = EmployeService.getEmployeById(widget.employeId);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'employé')),
      body: FutureBuilder<Employe>(
        future: employeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Employé non trouvé'));
          }

          final employe = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ListTile(title: const Text('Nom'), subtitle: Text(employe.nom ?? '')),
                ListTile(title: const Text('Prénom'), subtitle: Text(employe.prenom ?? '')),
                ListTile(title: const Text('Poste'), subtitle: Text(employe.poste ?? '')),
                ListTile(
                  title: const Text('Salaire (FCFA)'),
                  subtitle: Text(employe.salaire.toStringAsFixed(2)),
                ),
                if (employe.deletedAt != null)
                  ListTile(
                    title: const Text('Supprimé le'),
                    subtitle: Text(formatter.format(employe.deletedAt!)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
