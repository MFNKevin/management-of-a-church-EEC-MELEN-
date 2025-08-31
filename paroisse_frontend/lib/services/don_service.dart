import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/don_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class DonService {
  static const String apiRoute = '/api/dons/';
  static String get base => '${Config.baseUrl}$apiRoute';

  // 🔐 Récupère les headers avec le token
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

  // 📥 Liste paginée des dons
  static Future<List<Don>> fetchDons({int skip = 0, int limit = 10, bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Don.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement dons (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Détail don par ID
  static Future<Don> fetchDonById(int donId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$donId?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Don.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Don introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  // ➕ Créer un nouveau don (sans userId ni type dans le body)
  static Future<void> createDon(Don don) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(don.toJson()), // on envoie directement le modèle Don converti en JSON
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur création don (${response.statusCode}) : ${response.body}');
    }
  }

  // ✏️ Mise à jour don
  static Future<void> updateDon(Don don) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${don.donId}');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(don.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur mise à jour don (${response.statusCode}) : ${response.body}');
    }
  }

  // 🗑 Suppression logique
  static Future<void> softDeleteDon(int donId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$donId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression don (${response.statusCode}) : ${response.body}');
    }
  }

  // ♻️ Restaurer don supprimé
  static Future<void> restoreDon(int donId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$donId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration don (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Recherche dons par texte
  static Future<List<Don>> searchDons(String query, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${base}search/').replace(queryParameters: {
      'q': query,
      'include_deleted': includeDeleted.toString(),
    });
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Don.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche dons (${response.statusCode}) : ${response.body}');
    }
  }
}
