import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/budget_model.dart';
import 'package:paroisse_frontend/services/budget_service.dart';
import 'package:paroisse_frontend/constants/roles.dart';
import 'package:paroisse_frontend/constants/categories.dart'; // <- import du fichier categories.dart
import 'package:paroisse_frontend/utils/auth_token.dart';

class CreateBudgetScreen extends StatefulWidget {
  final Budget? budget;
  final bool initialDetailMode;
  final String? role;

  const CreateBudgetScreen({
    Key? key,
    this.budget,
    this.initialDetailMode = false,
    this.role,
  }) : super(key: key);

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _intituleController;
  late final TextEditingController _anneeController;
  late final TextEditingController _montantTotalController;
  late final TextEditingController _montantReelController;

  DateTime? _dateSoumission;
  String? _statut;
  String? _categorie;
  String? _sousCategorie;

  bool _loading = false;
  bool _isDetailMode = false;

  String? _role;
  int? _utilisateurId;

  final List<String> _statuts = ['Proposé', 'Approuvé', 'Rejeté', 'Archivé'];

  bool get _canEdit {
    if (_role == null) return false;
    return BudgetRoles.allowed.any(
      (allowedRole) => allowedRole.toLowerCase() == _role!.toLowerCase(),
    );
  }

  @override
  void initState() {
    super.initState();

    _isDetailMode = widget.initialDetailMode;

    _intituleController =
        TextEditingController(text: widget.budget?.intitule ?? '');
    _anneeController =
        TextEditingController(text: widget.budget?.annee?.toString() ?? '');
    _montantTotalController = TextEditingController(
        text: widget.budget?.montantTotal?.toStringAsFixed(2) ?? '');
    _montantReelController = TextEditingController(
        text: widget.budget?.montantReel?.toStringAsFixed(2) ?? '0.00');

    _dateSoumission = widget.budget?.dateSoumission;
    _statut = widget.budget?.statut ?? _statuts.first;

    // Gestion sécurisée de la catégorie
    _categorie = widget.budget?.categorie;
    if (_categorie == null || !categories.contains(_categorie)) {
      _categorie = categories.first;
    }

    // Gestion sécurisée de la sous-catégorie
    final sousList = getSousCategories(_categorie!);
    _sousCategorie = widget.budget?.sousCategorie;
    if (_sousCategorie == null || !sousList.contains(_sousCategorie)) {
      _sousCategorie = sousList.first;
    }

    _role = widget.role;

    if (_role == null || _utilisateurId == null) {
      _loadUserRoleAndId();
    }
  }

  Future<void> _loadUserRoleAndId() async {
    final role = await AuthToken.getUserRole();
    final id = await AuthToken.getUserId();
    setState(() {
      _role = role;
      _utilisateurId = id;
    });
  }

  @override
  void dispose() {
    _intituleController.dispose();
    _anneeController.dispose();
    _montantTotalController.dispose();
    _montantReelController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate() || _dateSoumission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final budget = Budget(
        budgetId: widget.budget?.budgetId ?? 0,
        intitule: _intituleController.text.trim(),
        annee: int.parse(_anneeController.text),
        montantTotal: double.parse(_montantTotalController.text),
        montantReel: double.parse(_montantReelController.text),
        dateSoumission: _dateSoumission!,
        statut: _statut ?? '',
        categorie: _categorie!,
        sousCategorie: _sousCategorie!,
        utilisateurId: _utilisateurId ?? 0,
        deletedAt: widget.budget?.deletedAt,
      );

      if (widget.budget == null) {
        await BudgetService.createBudget(budget);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget créé avec succès')),
        );
      } else {
        await BudgetService.updateBudget(budget);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget mis à jour avec succès')),
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

  Future<void> _softDeleteBudget() async {
    if (widget.budget == null) return;
    try {
      await BudgetService.softDeleteBudget(widget.budget!.budgetId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget supprimé')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression : $e')),
      );
    }
  }

  Future<void> _restoreBudget() async {
    if (widget.budget == null) return;
    try {
      await BudgetService.restoreBudget(widget.budget!.budgetId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget restauré')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur restauration : $e')),
      );
    }
  }

  Widget _buildDetailView() {
    final b = widget.budget!;
    final fmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          ListTile(title: const Text('Intitulé'), subtitle: Text(b.intitule)),
          ListTile(title: const Text('Année'), subtitle: Text('${b.annee}')),
          ListTile(title: const Text('Catégorie'), subtitle: Text(b.categorie ?? '-')),
          ListTile(title: const Text('Sous-catégorie'), subtitle: Text(b.sousCategorie ?? '-')),
          ListTile(title: const Text('Montant Total (FCFA)'), subtitle: Text(b.montantTotal.toStringAsFixed(2))),
          ListTile(title: const Text('Montant Réel (FCFA)'), subtitle: Text(b.montantReel.toStringAsFixed(2))),
          ListTile(title: const Text('Statut'), subtitle: Text(b.statut ?? '-')),
          ListTile(title: const Text('Date de Soumission'), subtitle: Text(fmt.format(b.dateSoumission))),
          if (b.deletedAt != null)
            ListTile(title: const Text('Supprimé le'), subtitle: Text(fmt.format(b.deletedAt!))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetExists = widget.budget != null;
    final isDeleted = widget.budget?.deletedAt != null;

    // Valeurs sûres pour les Dropdown
    final currentCategorie = _categorie ?? categories.first;
    final sousList = getSousCategories(currentCategorie);
    final currentSousCategorie =
        (_sousCategorie != null && sousList.contains(_sousCategorie))
            ? _sousCategorie
            : sousList.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          budgetExists
              ? (_isDetailMode ? 'Détail du Budget' : (isDeleted ? 'Budget Supprimé' : 'Modifier Budget'))
              : 'Nouveau Budget',
        ),
        actions: [
          if (budgetExists)
            IconButton(
              icon: Icon(_isDetailMode ? Icons.edit : Icons.info_outline),
              tooltip: _isDetailMode ? 'Modifier' : 'Voir détails',
              onPressed: () => setState(() => _isDetailMode = !_isDetailMode),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isDetailMode && budgetExists
              ? _buildDetailView()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _intituleController,
                          decoration: const InputDecoration(labelText: 'Intitulé'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                          enabled: !isDeleted && _canEdit,
                        ),
                        TextFormField(
                          controller: _anneeController,
                          decoration: const InputDecoration(labelText: 'Année'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            final annee = int.tryParse(v);
                            if (annee == null || annee < 2000 || annee > 2100) return 'Année invalide';
                            return null;
                          },
                          enabled: !isDeleted && _canEdit,
                        ),
                        DropdownButtonFormField<String>(
                          value: currentCategorie,
                          decoration: const InputDecoration(labelText: 'Catégorie'),
                          items: categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: !isDeleted && _canEdit
                              ? (val) {
                                  if (val == null) return;
                                  setState(() {
                                    _categorie = val;
                                    _sousCategorie = getSousCategories(val).first;
                                  });
                                }
                              : null,
                          validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                        ),
                        DropdownButtonFormField<String>(
                          value: currentSousCategorie,
                          decoration: const InputDecoration(labelText: 'Sous-catégorie'),
                          items: sousList
                              .map((sc) => DropdownMenuItem(value: sc, child: Text(sc)))
                              .toList(),
                          onChanged: !isDeleted && _canEdit
                              ? (val) {
                                  if (val == null) return;
                                  setState(() => _sousCategorie = val);
                                }
                              : null,
                          validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                        ),
                        TextFormField(
                          controller: _montantTotalController,
                          decoration: const InputDecoration(labelText: 'Montant Total (FCFA)'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            final val = double.tryParse(v);
                            if (val == null || val < 0) return 'Montant invalide';
                            return null;
                          },
                          enabled: !isDeleted && _canEdit,
                        ),
                        TextFormField(
                          controller: _montantReelController,
                          decoration: const InputDecoration(labelText: 'Montant Réel (FCFA)'),
                          keyboardType: TextInputType.number,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: !isDeleted && _canEdit ? _saveBudget : null,
                              child: const Text('Enregistrer'),
                            ),
                            if (budgetExists)
                              isDeleted
                                  ? ElevatedButton(
                                      onPressed: _restoreBudget,
                                      child: const Text('Restaurer'),
                                    )
                                  : ElevatedButton(
                                      onPressed: _softDeleteBudget,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Supprimer'),
                                    ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
