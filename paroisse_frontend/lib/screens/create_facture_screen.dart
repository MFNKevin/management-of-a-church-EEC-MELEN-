import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/facture_model.dart';

class CreateFactureScreen extends StatefulWidget {
  final Facture? facture;
  final bool initialDetailMode;
  final String? role;

  const CreateFactureScreen({
    Key? key,
    this.facture,
    this.initialDetailMode = false,
    this.role,
  }) : super(key: key);

  @override
  State<CreateFactureScreen> createState() => _CreateFactureScreenState();
}

class _CreateFactureScreenState extends State<CreateFactureScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _numeroController;
  late TextEditingController _montantController;
  late TextEditingController _descriptionController;
  late DateTime _date;

  bool _loading = false;
  bool _detailMode = false;

  @override
  void initState() {
    super.initState();
    _detailMode = true; // FORCER LECTURE SEULE
    _numeroController = TextEditingController(text: widget.facture?.numero ?? '');
    _montantController = TextEditingController(text: widget.facture?.montant.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.facture?.description ?? '');
    _date = widget.facture?.dateFacture ?? DateTime.now();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Désactivé car lecture seule
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = true; // Toujours en lecture seule
    final dateFormatted = DateFormat('dd/MM/yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la facture'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(labelText: 'Numéro'),
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                readOnly: isReadOnly,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Date : $dateFormatted'),
                trailing: null, // Pas de bouton calendrier
              ),
              const SizedBox(height: 20),
              // Plus de bouton Enregistrer ni modifier
            ],
          ),
        ),
      ),
    );
  }
}
