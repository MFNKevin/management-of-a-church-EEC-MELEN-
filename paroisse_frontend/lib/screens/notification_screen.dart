import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;
  List<NotificationModel> _notifications = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = NotificationService.fetchNotifications(search: _searchQuery);
    });
  }

  Future<void> _refresh() async {
    _loadNotifications();
    await _notificationsFuture;
  }

  Future<void> _markAsRead(int id) async {
    try {
      await NotificationService.markAsRead(id);
      _loadNotifications();
    } catch (e) {
      _showSnackBar("Échec de la lecture de la notification");
    }
  }

  Future<void> _deleteNotification(int id) async {
    final confirmed = await _showConfirmationDialog("Supprimer cette notification ?");
    if (!confirmed) return;

    try {
      await NotificationService.softDeleteNotification(id);
      _loadNotifications();
    } catch (e) {
      _showSnackBar("Échec de la suppression");
    }
  }

  Future<void> _restoreNotification(int id) async {
    try {
      await NotificationService.restoreNotification(id);
      _loadNotifications();
    } catch (e) {
      _showSnackBar("Échec de la restauration");
    }
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirmation"),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirmer")),
            ],
          ),
        )) ??
        false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
      case 'alerte':
        return Colors.red.shade600;
      case 'success':
      case 'confirmation':
        return Colors.green.shade600;
      case 'info':
      case 'information':
        return Colors.yellow.shade700;
      case 'question':
        return Colors.orange.shade400;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNotificationTile(NotificationModel notif) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final isDeleted = notif.deletedAt != null;

    return Card(
      color: isDeleted
          ? Colors.red.shade50
          : notif.estLue
              ? Colors.white
              : Colors.blue.shade50, // fond bleu clair pour non lu
      child: ListTile(
        title: Text(
          notif.titre,
          style: TextStyle(
            fontWeight: notif.estLue ? FontWeight.normal : FontWeight.bold,
            color: notif.estLue ? Colors.grey.shade800 : Colors.blue.shade900, // couleur titre selon lu/non lu
            decoration: isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.message,
              style: TextStyle(
                color: isDeleted ? Colors.red.shade400 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${notif.type.name.toUpperCase()} - ${formatter.format(notif.createdAt.toLocal())}',
              style: TextStyle(
                fontSize: 12,
                color: _typeColor(notif.type.name), // couleur selon type
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'read') {
              _markAsRead(notif.notificationId);
            } else if (value == 'delete') {
              _deleteNotification(notif.notificationId);
            } else if (value == 'restore') {
              _restoreNotification(notif.notificationId);
            }
          },
          itemBuilder: (context) => [
            if (!notif.estLue)
              const PopupMenuItem(value: 'read', child: Text('Marquer comme lue')),
            if (!isDeleted)
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            if (isDeleted)
              const PopupMenuItem(value: 'restore', child: Text('Restaurer')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue.shade800, // couleur de l'appbar
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            color: Colors.white, // icône blanche
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              width: 400,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  hintText: 'Rechercher dans les notifications...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _loadNotifications();
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NotificationModel>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Aucune notification trouvée."));
                } else {
                  _notifications = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
