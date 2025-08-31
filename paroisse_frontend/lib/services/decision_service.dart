import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/decision_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class DecisionService {
  static const String apiRoute = '/api/decisions/';
  static String get base => '${Config.baseUrl}$apiRoute';

  // Récupère les headers avec token d'authentification
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

  // Liste paginée des décisions
  static Future<List<Decision>> fetchDecisions({
    int skip = 0,
    int limit = 10,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    switch (response.statusCode) {
      case 200:
        final data = json.decode(response.body) as List;
        return data.map((e) => Decision.fromJson(e)).toList();
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      default:
        throw Exception('Erreur chargement décisions (${response.statusCode}) : ${response.body}');
    }
  }

  // Détail décision par ID
  static Future<Decision> fetchDecisionById(int decisionId, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$decisionId?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    switch (response.statusCode) {
      case 200:
        return Decision.fromJson(json.decode(response.body));
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      default:
        throw Exception('Décision introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  // Créer une nouvelle décision
  static Future<void> createDecision(Decision decision) async {
    final headers = await _getHeaders();
    final payload = decision.toJson();

    if (!payload.containsKey('reunion_id') || !payload.containsKey('auteur_id')) {
      throw Exception('Le reunion_id et auteur_id sont obligatoires pour créer une décision.');
    }

    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur création décision (${response.statusCode}) : ${response.body}');
    }
  }

  // Mise à jour décision
  static Future<void> updateDecision(Decision decision) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${decision.decisionId}');
    final payload = decision.toJson();

    if (!payload.containsKey('reunion_id') || !payload.containsKey('auteur_id')) {
      throw Exception('Le reunion_id et auteur_id sont obligatoires pour mettre à jour une décision.');
    }

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur mise à jour décision (${response.statusCode}) : ${response.body}');
    }
  }

  // Suppression logique
  static Future<void> softDeleteDecision(int decisionId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$decisionId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression décision (${response.statusCode}) : ${response.body}');
    }
  }

  // Restaurer décision supprimée
  static Future<void> restoreDecision(int decisionId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$decisionId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration décision (${response.statusCode}) : ${response.body}');
    }
  }

  // Recherche décisions par texte
  static Future<List<Decision>> searchDecisions(String query, {bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${base}search/').replace(queryParameters: {
      'q': query,
      'include_deleted': includeDeleted.toString(),
    });
    final response = await http.get(uri, headers: headers);

    switch (response.statusCode) {
      case 200:
        final data = json.decode(response.body) as List;
        return data.map((e) => Decision.fromJson(e)).toList();
      case 401:
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      default:
        throw Exception('Erreur recherche décisions (${response.statusCode}) : ${response.body}');
    }
  }
}
