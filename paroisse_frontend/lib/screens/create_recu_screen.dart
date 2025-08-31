import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paroisse_frontend/models/recu_model.dart';
import 'package:paroisse_frontend/services/recu_service.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';

class CreateRecuScreen extends StatefulWidget {
  // Suppression du paramètre recu et detailMode, ce screen sert seulement à créer
  final String? role;

  const CreateRecuScreen({
    Key? key,
    this.role,
  }) : super(key: key);

  @override
  State<CreateRecuScreen> createState() => _CreateRecuScreenState();
}

class _CreateRecuScreenState extends State<CreateRecuScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _montantController;
  late TextEditingController _descriptionController;
  late DateTime _dateEmission;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateEmission = DateTime.now();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRecu() async {
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

      final newRecu = Recu(
        recuId: 0, // 0 ou null, sera attribué par le backend
        dateEmission: _dateEmission,
        montant: double.parse(_montantController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        utilisateurId: userId,
        deletedAt: null,
        montantTotal: null,
      );

      await RecuService.createRecu(newRecu);

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
      initialDate: _dateEmission,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dateEmission) {
      setState(() {
        _dateEmission = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(_dateEmission);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau reçu'),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Veuillez saisir un montant';
                  final montant = double.tryParse(val);
                  if (montant == null || montant <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Date : $dateFormatted'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _saveRecu,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
