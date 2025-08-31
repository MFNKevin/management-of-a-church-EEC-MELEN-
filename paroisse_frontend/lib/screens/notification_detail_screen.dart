import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int notificationId;

  const NotificationDetailScreen({
    super.key,
    required this.apiBaseUrl,
    required this.notificationId,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late Future<NotificationModel> _notificationFuture;
  bool _processing = false;

  late NotificationService _service;

  @override
  void initState() {
    super.initState();
    _service = NotificationService(baseUrl: widget.apiBaseUrl);
    _loadNotification();
  }

  void _loadNotification() {
    setState(() {
      _notificationFuture = _service.getNotificationById(widget.notificationId);
    });
  }

  Future<void> _performAction(Future<void> Function() action, {String? successMessage}) async {
    setState(() => _processing = true);
    try {
      await action();
      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
      _loadNotification();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.estLue) return;
    await _performAction(() => _service.markNotificationAsRead(notif.notificationId),
        successMessage: 'Notification marquée comme lue');
  }

  Future<void> _deleteNotification(NotificationModel notif) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await _performAction(() => _service.deleteNotification(notif.notificationId),
        successMessage: 'Notification supprimée');

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail Notification'),
      ),
      body: FutureBuilder<NotificationModel>(
        future: _notificationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Notification introuvable'));
          }

          final notif = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  notif.titre,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 12),
                Text(
                  notif.message,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                const SizedBox(height: 20),
                Text(
                  'Type : ${notif.type}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Date création : ${notif.createdAt.toLocal().toString().split('.').first}',
                ),
                const SizedBox(height: 20),
                if (!notif.estLue)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.mark_email_read),
                    label: const Text('Marquer comme lue'),
                    onPressed: _processing ? null : () => _markAsRead(notif),
                  ),
                if (notif.estLue) ...[
                  const Text('Cette notification est déjà lue'),
                  const SizedBox(height: 20),
                ],
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                  onPressed: _processing ? null : () => _deleteNotification(notif),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
