import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/inspecteur_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class InspecteurService {
  static const String apiRoute = '/api/inspecteurs/';
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

  // 📥 Récupérer tous les inspecteurs (option pour inclure ceux supprimés)
  static Future<List<Inspecteur>> fetchInspecteurs({bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Inspecteur.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement inspecteurs (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Récupérer un inspecteur par ID
  static Future<Inspecteur> getInspecteurById(int inspecteurId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$inspecteurId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Inspecteur.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement inspecteur ($inspecteurId) : ${response.body}');
    }
  }

  // ➕ Créer un nouvel inspecteur
  static Future<void> createInspecteur(Inspecteur inspecteur) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(inspecteur.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur création inspecteur (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔄 Mettre à jour un inspecteur existant
  static Future<void> updateInspecteur(Inspecteur inspecteur) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${inspecteur.inspecteurId}');
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(inspecteur.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur mise à jour inspecteur (${response.statusCode}) : ${response.body}');
    }
  }

  // 🗑️ Suppression logique (soft delete)
  static Future<void> softDeleteInspecteur(int inspecteurId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$inspecteurId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression inspecteur (${response.statusCode}) : ${response.body}');
    }
  }

  // ♻️ Restaurer un inspecteur supprimé
  static Future<void> restoreInspecteur(int inspecteurId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$inspecteurId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration inspecteur (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Recherche simple par terme (nom, prenom, email)
  static Future<List<Inspecteur>> searchInspecteurs({required String searchTerm, bool includeDeleted = false}) async {
    final headers = await _getHeaders();

    final uri = Uri.parse('$base/search').replace(queryParameters: {
      'search_term': searchTerm,
      'include_deleted': includeDeleted.toString(),
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Inspecteur.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche inspecteurs (${response.statusCode}) : ${response.body}');
    }
  }
}
