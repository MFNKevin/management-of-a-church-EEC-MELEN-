import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/quete_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class QueteService {
  static const String apiRoute = '/api/quetes/';
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

  static Future<List<Quete>> fetchQuetes({
    int skip = 0,
    int limit = 10,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Quete.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement quêtes (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<Quete> fetchQueteById(int queteId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$queteId?include_deleted=$includeDeleted');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Quete.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Quête introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> createQuete(Quete quete) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(quete.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur création quête (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> updateQuete(Quete quete) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${quete.queteId}');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(quete.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur mise à jour quête (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> softDeleteQuete(int queteId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$queteId');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression quête (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> restoreQuete(int queteId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$queteId');

    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration quête (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<List<Quete>> searchQuetes(String query, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${base}search/').replace(queryParameters: {
      'q': query,
      'include_deleted': includeDeleted.toString(),
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Quete.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche quêtes (${response.statusCode}) : ${response.body}');
    }
  }
}
