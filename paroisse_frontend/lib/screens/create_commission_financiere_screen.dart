import 'package:flutter/material.dart';
import '../models/commission_financiere_model.dart';
import '../services/commission_financiere_service.dart';

class CreateCommissionFinanciereScreen extends StatefulWidget {
  final CommissionFinanciere? commission; // null si création

  const CreateCommissionFinanciereScreen({Key? key, this.commission}) : super(key: key);

  @override
  State<CreateCommissionFinanciereScreen> createState() => _CreateCommissionFinanciereScreenState();
}

class _CreateCommissionFinanciereScreenState extends State<CreateCommissionFinanciereScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descController = TextEditingController();

  final CommissionFinanciereService _service = CommissionFinanciereService();

  bool get isEditing => widget.commission != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nomController.text = widget.commission!.nom;
      _descController.text = widget.commission!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Création ou mise à jour de l'objet
      final commission = CommissionFinanciere(
        commissionId: isEditing ? widget.commission!.commissionId : 0,
        nom: _nomController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );

      try {
        if (isEditing) {
          await _service.updateCommission(commission);
        } else {
          await _service.createCommission(commission);
        }

        if (mounted) {
          Navigator.pop(context, true); // retour avec indicateur de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Commission mise à jour avec succès'
                    : 'Commission créée avec succès',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Commission' : 'Créer Commission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la commission',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Mettre à jour' : 'Créer'),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
