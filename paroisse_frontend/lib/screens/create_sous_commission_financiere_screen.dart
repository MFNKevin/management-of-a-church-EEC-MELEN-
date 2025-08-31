import 'package:flutter/material.dart';
import '../models/sous_commission_financiere_model.dart';
import '../services/sous_commission_financiere_service.dart';

class CreateSousCommissionFinanciereScreen extends StatefulWidget {
  final SousCommissionFinanciere? sousCommission;

  const CreateSousCommissionFinanciereScreen({Key? key, this.sousCommission}) : super(key: key);

  @override
  State<CreateSousCommissionFinanciereScreen> createState() => _CreateSousCommissionFinanciereScreenState();
}

class _CreateSousCommissionFinanciereScreenState extends State<CreateSousCommissionFinanciereScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descController = TextEditingController();
  final SousCommissionFinanciereService _service = SousCommissionFinanciereService();

  bool get isEditing => widget.sousCommission != null;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nomController.text = widget.sousCommission!.nom;
      _descController.text = widget.sousCommission!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final sousCommission = SousCommissionFinanciere(
      sousCommissionId: isEditing ? widget.sousCommission!.sousCommissionId : 0,
      nom: _nomController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );

    try {
      if (isEditing) {
        await _service.updateSousCommission(sousCommission);
      } else {
        await _service.createSousCommission(sousCommission);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Sous-commission mise à jour avec succès'
                  : 'Sous-commission créée avec succès',
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Sous-commission' : 'Créer Sous-commission'),
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
                  labelText: 'Nom de la sous-commission',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ce champ est requis'
                    : null,
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
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Mettre à jour' : 'Créer'),
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
