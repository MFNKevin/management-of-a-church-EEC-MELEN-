import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/utils/auth_token.dart';
import '../models/notification_model.dart';
import '../config.dart';

class NotificationService {
  static const String apiRoute = '/api/notifications';
  static String get base => '${Config.baseUrl}$apiRoute';

  // 🔐 Récupérer les headers avec le token JWT
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthToken.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token non disponible. Veuillez vous connecter.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 📥 Récupérer toutes les notifications (option recherche)
  static Future<List<NotificationModel>> fetchNotifications({String? search}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(base).replace(
      queryParameters: search != null && search.isNotEmpty ? {'keyword': search} : null,
    );

    final response = await http.get(uri, headers: headers);

    switch (response.statusCode) {
      case 200:
        final List data = json.decode(response.body);
        return data.map((e) => NotificationModel.fromJson(e)).toList();
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      default:
        throw Exception('Erreur chargement notifications (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Récupérer une notification par ID
  static Future<NotificationModel> getNotificationById(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$base/$id');

    final response = await http.get(uri, headers: headers);

    switch (response.statusCode) {
      case 200:
        return NotificationModel.fromJson(json.decode(response.body));
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      case 404:
        throw Exception('Notification non trouvée.');
      default:
        throw Exception('Erreur (${response.statusCode}) : ${response.body}');
    }
  }

  // ➕ Créer une nouvelle notification
  static Future<void> createNotification(NotificationModel notification) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(base);
    final body = json.encode(notification.toJson());

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 201) return;

    switch (response.statusCode) {
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      default:
        throw Exception('Erreur création notification (${response.statusCode}) : ${response.body}');
    }
  }

  // 🗑️ Suppression logique (soft delete)
  static Future<void> softDeleteNotification(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$base/$id');

    final response = await http.delete(uri, headers: headers);

    if (response.statusCode == 200) return;

    switch (response.statusCode) {
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      case 404:
        throw Exception('Notification introuvable.');
      default:
        throw Exception('Erreur suppression notification (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔄 Marquer comme lue
  static Future<void> markAsRead(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$base/$id/lu');

    final response = await http.put(uri, headers: headers);

    if (response.statusCode == 200) return;

    switch (response.statusCode) {
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      case 404:
        throw Exception('Notification introuvable.');
      default:
        throw Exception('Erreur mise à jour lecture notification (${response.statusCode}) : ${response.body}');
    }
  }

  // ♻️ Restaurer une notification supprimée
  static Future<void> restoreNotification(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$base/restore/$id');

    final response = await http.put(uri, headers: headers);

    if (response.statusCode == 200) return;

    switch (response.statusCode) {
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      case 404:
        throw Exception('Notification introuvable à restaurer.');
      default:
        throw Exception('Erreur restauration notification (${response.statusCode}) : ${response.body}');
    }
  }
}
