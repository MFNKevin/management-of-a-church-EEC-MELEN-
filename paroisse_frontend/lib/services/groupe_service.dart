import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/groupe_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class GroupeService {
  static const String apiRoute = '/api/groupes/';
  static String get base => '${Config.baseUrl}$apiRoute';

  // 🔐 Récupère les headers avec le token JWT
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

  // 📥 Récupère tous les groupes (avec option d’inclure les supprimés)
  static Future<List<Groupe>> fetchGroupes({bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(base).replace(queryParameters: {
      'include_deleted': includeDeleted.toString(),
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => Groupe.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
        'Erreur lors du chargement des groupes (${response.statusCode}) : ${response.body}',
      );
    }
  }

  // 🔎 Récupère un groupe par ID
  static Future<Groupe?> getGroupeById(
    int groupeId, {
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$base$groupeId').replace(queryParameters: {
      'include_deleted': includeDeleted.toString(),
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Groupe.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
        'Erreur lors du chargement du groupe ($groupeId) : ${response.body}',
      );
    }
  }

  // ➕ Crée un nouveau groupe
  static Future<void> createGroupe(Groupe groupe) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(groupe.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
        'Erreur lors de la création du groupe (${response.statusCode}) : ${response.body}',
      );
    }
  }

  // 🔄 Met à jour un groupe existant
  static Future<void> updateGroupe(Groupe groupe) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${groupe.groupeId}');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(groupe.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
        'Erreur lors de la mise à jour du groupe (${response.statusCode}) : ${response.body}',
      );
    }
  }

  // 🗑️ Supprime logiquement un groupe (soft delete)
  static Future<void> softDeleteGroupe(int groupeId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$groupeId');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
        'Erreur lors de la suppression du groupe (${response.statusCode}) : ${response.body}',
      );
    }
  }

  // ♻️ Restaure un groupe supprimé
  static Future<void> restoreGroupe(int groupeId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$groupeId');

    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
        'Erreur lors de la restauration du groupe (${response.statusCode}) : ${response.body}',
      );
    }
  }

  // 🔍 Recherche paginée avec filtre par nom ou description
  static Future<List<Groupe>> searchGroupes({
    required String query,
    int skip = 0,
    int limit = 50,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();

    final queryParameters = {
      'query': query,
      'skip': skip.toString(),
      'limit': limit.toString(),
      'include_deleted': includeDeleted.toString(),
    };

    final uri = Uri.parse('${base}search').replace(queryParameters: queryParameters);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => Groupe.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
        'Erreur lors de la recherche des groupes (${response.statusCode}) : ${response.body}',
      );
    }
  }
}
