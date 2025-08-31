// lib/screens/create_salaire_screen.dart

import 'package:flutter/material.dart';
import 'package:paroisse_frontend/models/salaire_model.dart';
import 'package:paroisse_frontend/services/salaire_service.dart';
import 'package:paroisse_frontend/services/employe_service.dart';
import 'package:intl/intl.dart';
import '../constants/roles.dart';

// === CREATE SALAIRE SCREEN ===
class CreateSalaireScreen extends StatefulWidget {
  final Salaire? salaire; // null = création
  final String? role; // rôle utilisateur pour contrôle d’accès

  const CreateSalaireScreen({this.salaire, this.role, Key? key}) : super(key: key);

  @override
  State<CreateSalaireScreen> createState() => _CreateSalaireScreenState();
}

class _CreateSalaireScreenState extends State<CreateSalaireScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montantController;
  late DateTime _selectedDate;
  bool _loading = false;

  List<Map<String, dynamic>> _employes = [];
  int? _selectedEmployeId;

  // Contrôle accès
  bool get canEdit =>
      widget.role != null &&
      SalaireRoles.allowed.map((e) => e.toLowerCase()).contains(widget.role!.toLowerCase());

  bool get canDelete =>
      widget.role != null &&
      widget.role!.toLowerCase() == Roles.administrateur.toLowerCase();

  @override
  void initState() {
    super.initState();
    _montantController =
        TextEditingController(text: widget.salaire?.montant.toString() ?? '');
    _selectedDate = widget.salaire?.datePaiement ?? DateTime.now();
    _selectedEmployeId = widget.salaire?.employeId;
    _loadEmployes();
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployes() async {
    try {
      final data = await EmployeService.fetchEmployes();
      setState(() {
        _employes = data
            .map((e) => {
                  'id': e.employeId,
                  'nom': e.nom,
                  'prenom': e.prenom,
                  'poste': e.poste,
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur chargement employés: $e')));
    }
  }

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un employé')));
      return;
    }

    // Règle métier : un salaire existant ne peut pas être modifié
    if (widget.salaire != null) return;

    final salaire = Salaire(
      salaireId: 0,
      montant: double.parse(_montantController.text.trim()),
      datePaiement: _selectedDate,
      employeId: _selectedEmployeId!,
      utilisateurId: 0, // à définir depuis le backend si nécessaire
      createdAt: DateTime.now(),
      deletedAt: null,
    );

    await _performAction(() => SalaireService.createSalaire(salaire));
  }

  Future<void> _softDelete() async {
    if (widget.salaire == null) return;
    await _performAction(() => SalaireService.deleteSalaire(widget.salaire!.salaireId));
  }

  Future<void> _restore() async {
    if (widget.salaire == null) return;
    await _performAction(() => SalaireService.restoreSalaire(widget.salaire!.salaireId));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.salaire?.deletedAt != null;
    final isReadOnly = isDeleted || !canEdit || widget.salaire != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salaire == null
            ? 'Ajouter un Salaire'
            : isDeleted
                ? 'Salaire Supprimé'
                : 'Détails du Salaire'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !isReadOnly,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Champ requis';
                  final montant = double.tryParse(value.trim());
                  if (montant == null || montant <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedEmployeId,
                items: _employes
                    .map((e) => DropdownMenuItem<int>(
                          value: e['id'],
                          child: Text('${e['prenom']} ${e['nom']} (${e['poste']})'),
                        ))
                    .toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedEmployeId = val),
                decoration: const InputDecoration(
                  labelText: 'Employé',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Veuillez sélectionner un employé' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Date paiement : '),
                  Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: isReadOnly ? null : _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (!isDeleted && canEdit && widget.salaire == null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Enregistrer'),
                    onPressed: _submit,
                  ),
                if (widget.salaire != null && !isDeleted && canDelete)
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

// === SALAIRE DETAIL SCREEN ===
class SalaireDetailScreen extends StatelessWidget {
  final Salaire salaire;

  const SalaireDetailScreen({required this.salaire, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du salaire')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
                title: const Text('Employé ID'),
                subtitle: Text(salaire.employeId.toString())),
            ListTile(
                title: const Text('Montant (FCFA)'),
                subtitle: Text(salaire.montant.toStringAsFixed(2))),
            ListTile(
                title: const Text('Date paiement'),
                subtitle: Text(formatter.format(salaire.datePaiement))),
            ListTile(
                title: const Text('Créé le'),
                subtitle: Text(formatter.format(salaire.createdAt))),
            if (salaire.deletedAt != null)
              ListTile(
                  title: const Text('Supprimé le'),
                  subtitle: Text(formatter.format(salaire.deletedAt!))),
          ],
        ),
      ),
    );
  }
}
