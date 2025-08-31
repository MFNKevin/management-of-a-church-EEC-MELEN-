import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

// === NOTIFICATION CREATE SCREEN ===

class NotificationCreateScreen extends StatefulWidget {
  final String? role; // Pour gestion des rôles (si utile)

  const NotificationCreateScreen({super.key, this.role});

  @override
  State<NotificationCreateScreen> createState() => _NotificationCreateScreenState();
}

class _NotificationCreateScreenState extends State<NotificationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _messageController;
  late TextEditingController _utilisateurIdController;

  TypeNotificationEnum _selectedType = TypeNotificationEnum.info;
  bool _loading = false;

  final List<TypeNotificationEnum> _types = TypeNotificationEnum.values;

  bool get canCreate => widget.role != null && widget.role!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _messageController = TextEditingController();
    _utilisateurIdController = TextEditingController();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    _utilisateurIdController.dispose();
    super.dispose();
  }

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification créée avec succès')),
        );
        Navigator.pop(context, true);
      }
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final notification = NotificationModel(
      notificationId: 0, // Sera ignoré côté backend
      titre: _titreController.text.trim(),
      message: _messageController.text.trim(),
      type: _selectedType,
      estLue: false,
      emailEnvoye: false,
      emailEnvoyeAt: null,
      createdAt: DateTime.now(),
      updatedAt: null,
      deletedAt: null,
      utilisateurId: _utilisateurIdController.text.trim().isNotEmpty
          ? int.tryParse(_utilisateurIdController.text.trim())
          : null,
    );

    _performAction(() => NotificationService.createNotification(notification));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une notification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Le titre est requis' : null,
                enabled: !_loading && canCreate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Le message est requis' : null,
                enabled: !_loading && canCreate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TypeNotificationEnum>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type de notification'),
                items: _types
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: !_loading && canCreate
                    ? (value) => setState(() => _selectedType = value ?? TypeNotificationEnum.info)
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _utilisateurIdController,
                decoration: const InputDecoration(
                  labelText: 'ID utilisateur (optionnel)',
                  hintText: 'Ex : 1',
                ),
                keyboardType: TextInputType.number,
                enabled: !_loading && canCreate,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Créer'),
                      onPressed: canCreate ? _submit : null,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
