import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/offrande_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class OffrandeService {
  static const String apiRoute = '/api/offrandes/';
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

  static Future<List<Offrande>> fetchOffrandes({int skip = 0, int limit = 10, bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Offrande.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement offrandes (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<Offrande> fetchOffrandeById(int offrandeId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$offrandeId?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Offrande.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Offrande introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> createOffrande(Offrande offrande) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(offrande.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur création offrande (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> updateOffrande(Offrande offrande) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${offrande.offrandeId}');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(offrande.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur mise à jour offrande (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> softDeleteOffrande(int offrandeId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$offrandeId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression offrande (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> restoreOffrande(int offrandeId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$offrandeId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration offrande (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<List<Offrande>> searchOffrandes(String query, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${base}search/').replace(queryParameters: {
      'q': query,
      'include_deleted': includeDeleted.toString(),
    });
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Offrande.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche offrandes (${response.statusCode}) : ${response.body}');
    }
  }
}
