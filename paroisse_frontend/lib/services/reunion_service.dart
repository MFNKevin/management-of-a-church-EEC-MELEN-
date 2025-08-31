import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/reunion_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class ReunionService {
  static const String apiRoute = '/api/reunions/';
  static String get base => '${Config.baseUrl}$apiRoute';

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

  // 🔹 Récupération de toutes les réunions
  static Future<List<Reunion>> fetchReunions({bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Reunion.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement réunions (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔹 Récupération d'une réunion par ID
  static Future<Reunion> getReunionById(int reunionId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$reunionId');
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Reunion.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement réunion ($reunionId) : ${response.body}');
    }
  }

  // 🔹 Création d'une réunion
  static Future<Reunion> createReunion(Reunion reunion) async {
    final headers = await _getHeaders();
    final Map<String, dynamic> payload = reunion.toJson();

    // Assurer que "convoques" est toujours présent et non null
    payload['convoques'] = reunion.convoques ?? [];

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Reunion.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur création réunion (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔹 Mise à jour d'une réunion
  static Future<Reunion> updateReunion(Reunion reunion) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${reunion.reunionId}');
    final Map<String, dynamic> payload = reunion.toJson();

    // Assurer que "convoques" est toujours présent et non null
    payload['convoques'] = reunion.convoques ?? [];

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Reunion.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur mise à jour réunion (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔹 Suppression logique (soft delete)
  static Future<void> softDeleteReunion(int reunionId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$reunionId');
    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression réunion (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔹 Restauration d'une réunion supprimée
  static Future<void> restoreReunion(int reunionId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$reunionId');
    final response = await http.put(url, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration réunion (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔹 Recherche de réunions
  static Future<List<Reunion>> searchReunions(String keyword, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final queryParams = {
      'keyword': keyword,
      'include_deleted': includeDeleted.toString(),
    };
    final uri = Uri.parse('$base/search').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Reunion.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche réunions (${response.statusCode}) : ${response.body}');
    }
  }
}
