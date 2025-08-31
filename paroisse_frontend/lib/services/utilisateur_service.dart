import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/utilisateur_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class UtilisateurService {
  static const String apiRoute = '/api/utilisateurs/';
  static String get base => '${Config.baseUrl}$apiRoute';

  // Obtient les headers avec token d'authentification
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthToken.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ Vérifie si un email est déjà utilisé
  static Future<bool> checkEmailExists(String email) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}email-exists?email=$email');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['exists'] == true;
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur lors de la vérification de l\'email : ${response.body}');
    }
  }

  // Récupère la liste des utilisateurs (option pour inclure les supprimés)
  static Future<List<Utilisateur>> fetchUtilisateurs({bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}').replace(queryParameters: {
      'include_deleted': includeDeleted.toString(),
    });
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Utilisateur.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement utilisateurs : ${response.body}');
    }
  }

  // Récupère un utilisateur par son ID
  static Future<Utilisateur> getUtilisateurById(int utilisateurId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}$utilisateurId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Utilisateur.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (response.statusCode == 404) {
      throw Exception('Utilisateur non trouvé.');
    } else {
      throw Exception('Erreur récupération utilisateur : ${response.body}');
    }
  }

  // Crée un nouvel utilisateur
  static Future<void> createUtilisateur(Utilisateur utilisateur) async {
    final headers = await _getHeaders();
    final body = utilisateur.toJson();
    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur création utilisateur : ${response.body}');
    }
  }

  // Met à jour un utilisateur existant
  static Future<void> updateUtilisateur(Utilisateur utilisateur) async {
    final headers = await _getHeaders();
    final body = utilisateur.toJson();
    final url = Uri.parse('${base}${utilisateur.utilisateurId}');
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour utilisateur : ${response.body}');
    }
  }

  // Suppression douce (soft delete)
  static Future<void> softDeleteUtilisateur(int utilisateurId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}$utilisateurId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression utilisateur : ${response.body}');
    }
  }

  // Restauration d’un utilisateur supprimé
  static Future<void> restoreUtilisateur(int utilisateurId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$utilisateurId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur restauration utilisateur : ${response.body}');
    }
  }
}
