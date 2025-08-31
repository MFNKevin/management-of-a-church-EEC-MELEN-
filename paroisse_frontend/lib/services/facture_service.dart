import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/facture_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class FactureService {
  static const String apiRoute = '/api/factures/';
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

  static Future<List<Facture>> fetchFactures({
    int skip = 0,
    int limit = 10,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Facture.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement factures (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<Facture> fetchFactureById(int factureId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$factureId?include_deleted=$includeDeleted');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Facture.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Facture introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<void> softDeleteFacture(int factureId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$factureId');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        final success = data['success'] ?? false;
        final message = data['message'] ?? 'Erreur inconnue';

        if (!success) {
          // Ne pas throw une Exception brutale mais renvoyer un message d'erreur
          throw Exception('Erreur suppression facture : $message');
        }
        // succès, rien à faire
        return;
      } else {
        throw Exception('Réponse inattendue du serveur.');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur suppression facture (${response.statusCode}) : ${response.body}');
    }
  }


  static Future<void> restoreFacture(int factureId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$factureId');

    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration facture (${response.statusCode}) : ${response.body}');
    }
  }

  static Future<List<Facture>> searchFactures(String query, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${base}search/').replace(queryParameters: {
      'query': query,
      'include_deleted': includeDeleted.toString(),
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Facture.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche factures (${response.statusCode}) : ${response.body}');
    }
  }
}
