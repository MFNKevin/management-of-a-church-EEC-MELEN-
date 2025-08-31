import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/salaire_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class SalaireService {
  static const String apiRoute = '/api/salaires/';
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

  static void _handleUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }
  }

  static Future<List<Salaire>> fetchSalaires({int skip = 0, int limit = 10, bool includeDeleted = false}) async {
    final headers = await _getHeaders();

    // Conversion bool => string dans l'URL
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=${includeDeleted.toString()}');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Salaire.fromJson(e)).toList();
    } else {
      _handleUnauthorized(response);
      throw Exception('Erreur chargement salaires (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<Salaire> fetchSalaireById(int salaireId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$salaireId?include_deleted=${includeDeleted.toString()}');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Salaire.fromJson(json.decode(response.body));
    } else {
      _handleUnauthorized(response);
      throw Exception('Salaire introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> createSalaire(Salaire salaire) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(salaire.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      _handleUnauthorized(response);
      throw Exception('Erreur création salaire (${response.statusCode}) : ${response.body}');
    }
  }


  static Future<void> deleteSalaire(int salaireId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$salaireId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      _handleUnauthorized(response);
      throw Exception('Erreur suppression salaire (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> restoreSalaire(int salaireId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$salaireId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      _handleUnauthorized(response);
      throw Exception('Erreur restauration salaire (${response.statusCode}) : ${response.body}');
    }
  }
}
