import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/quete_model.dart';
import 'package:paroisse_frontend/services/quete_service.dart';
import 'package:paroisse_frontend/utils/auth_token.dart'; // Pour récupérer l'ID utilisateur connecté

class CreateQueteScreen extends StatefulWidget {
  final Quete? quete;
  final bool initialDetailMode;
  final String? role;

  const CreateQueteScreen({
    Key? key,
    this.quete,
    this.initialDetailMode = false,
    this.role,
  }) : super(key: key);

  @override
  State<CreateQueteScreen> createState() => _CreateQueteScreenState();
}

class _CreateQueteScreenState extends State<CreateQueteScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _libelleController;
  late TextEditingController _montantController;
  late DateTime _date;

  bool _loading = false;
  bool _detailMode = false;

  @override
  void initState() {
    super.initState();
    _detailMode = widget.initialDetailMode;
    _libelleController = TextEditingController(text: widget.quete?.libelle ?? '');
    _montantController = TextEditingController(text: widget.quete?.montant.toString() ?? '');
    _date = widget.quete?.dateQuete ?? DateTime.now();
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _saveQuete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      int? userIdNullable = await AuthToken.getUserId();
      if (userIdNullable == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non connecté.')),
          );
        }
        setState(() => _loading = false);
        return;
      }
      int userId = userIdNullable;

      final newQuete = Quete(
        queteId: widget.quete?.queteId ?? 0,
        libelle: _libelleController.text.trim(),
        montant: double.parse(_montantController.text.trim()),
        dateQuete: _date,
        utilisateurId: userId,
        deletedAt: null,
        montantTotal: widget.quete?.montantTotal,
      );

      if (widget.quete == null) {
        await QueteService.createQuete(newQuete);
      } else {
        await QueteService.updateQuete(newQuete);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
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
            ? 'Détails de la quête'
            : (widget.quete == null ? 'Nouvelle Quête' : 'Modifier Quête')),
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
                controller: _libelleController,
                decoration: const InputDecoration(labelText: 'Libellé'),
                readOnly: isReadOnly,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez saisir le libellé' : null,
              ),
              const SizedBox(height: 12),
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
                  onPressed: _loading ? null : _saveQuete,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(widget.quete == null ? 'Enregistrer' : 'Mettre à jour'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
