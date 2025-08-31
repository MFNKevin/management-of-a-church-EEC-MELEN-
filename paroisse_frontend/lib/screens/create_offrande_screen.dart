import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/offrande_model.dart';
import 'package:paroisse_frontend/services/offrande_service.dart';

class CreateOffrandeScreen extends StatefulWidget {
  final Offrande? offrande;
  final bool initialDetailMode;
  final String? role;

  const CreateOffrandeScreen({Key? key, this.offrande, this.initialDetailMode = false, this.role}) : super(key: key);

  @override
  State<CreateOffrandeScreen> createState() => _CreateOffrandeScreenState();
}

class _CreateOffrandeScreenState extends State<CreateOffrandeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _montantController;
  late TextEditingController _descriptionController;
  late TextEditingController _typeController;
  late DateTime _date;

  bool _loading = false;
  bool _detailMode = false;

  @override
  void initState() {
    super.initState();
    _detailMode = widget.initialDetailMode;

    _montantController = TextEditingController(text: widget.offrande?.montant.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.offrande?.description ?? '');
    _typeController = TextEditingController(text: widget.offrande?.type ?? '');
    _date = widget.offrande?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _saveOffrande() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final newOffrande = Offrande(
        offrandeId: widget.offrande?.offrandeId ?? 0, // 0 si nouvelle offrande
        montant: double.parse(_montantController.text.trim()),
        date: _date,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        type: _typeController.text.trim(),
        utilisateurId: 0, // À remplacer côté backend avec user connecté
        deletedAt: null, // Ne pas envoyer de valeur supprimée ici
      );

      if (widget.offrande == null) {
        await OffrandeService.createOffrande(newOffrande);
      } else {
        await OffrandeService.updateOffrande(newOffrande);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = _detailMode;
    final dateFormatted = DateFormat('dd/MM/yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(
        title: Text(_detailMode
            ? 'Détails de l\'offrande'
            : (widget.offrande == null ? 'Nouvelle Offrande' : 'Modifier Offrande')),
        actions: [
          if (_detailMode)
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _detailMode = false;
                });
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
                controller: _montantController,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                readOnly: isReadOnly,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Veuillez saisir un montant';
                  final montant = double.tryParse(val);
                  if (montant == null || montant <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type d\'offrande'),
                readOnly: isReadOnly,
                validator: (val) => (val == null || val.isEmpty) ? 'Veuillez saisir le type d\'offrande' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                readOnly: isReadOnly,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Date : $dateFormatted'),
                trailing: isReadOnly
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickDate,
                      ),
              ),
              const SizedBox(height: 20),
              if (!isReadOnly)
                ElevatedButton(
                  onPressed: _loading ? null : _saveOffrande,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(widget.offrande == null ? 'Enregistrer' : 'Mettre à jour'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
