import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/recu_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class RecuService {
  static const String apiRoute = '/api/recus/';
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

  static Future<List<Recu>> fetchRecus({
    int skip = 0,
    int limit = 10,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Recu.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur lors du chargement des reçus (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<Recu> fetchRecuById(int recuId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$recuId?include_deleted=$includeDeleted');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Recu.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Reçu introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> createRecu(Recu recu) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(recu.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur lors de la création du reçu (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> softDeleteRecu(int recuId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$recuId');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur lors de la suppression du reçu (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> restoreRecu(int recuId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$recuId');

    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur lors de la restauration du reçu (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<List<Recu>> searchRecus(String query, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${base}search/').replace(queryParameters: {
      'keyword': query,
      'include_deleted': includeDeleted.toString(),
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Recu.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur lors de la recherche des reçus (${response.statusCode}) : ${response.body}');
    }
  }
}
