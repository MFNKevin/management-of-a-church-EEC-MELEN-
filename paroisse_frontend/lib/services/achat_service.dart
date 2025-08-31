import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/achat_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class AchatService {
  static const String apiRoute = '/api/achats/';
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

  // 📥 Récupérer tous les achats (option pour inclure ceux supprimés)
  static Future<List<Achat>> fetchAchats({bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Achat.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement achats (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Récupérer un achat par ID
  static Future<Achat> getAchatById(int achatId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$achatId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Achat.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement achat ($achatId) : ${response.body}');
    }
  }

  // ➕ Créer un nouvel achat
  static Future<void> createAchat(Achat achat) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(achat.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur création achat (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔄 Mettre à jour un achat existant
  static Future<void> updateAchat(Achat achat) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${achat.achatId}');
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(achat.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur mise à jour achat (${response.statusCode}) : ${response.body}');
    }
  }

  // 🗑️ Suppression logique (soft delete)
  static Future<void> softDeleteAchat(int achatId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$achatId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur suppression achat (${response.statusCode}) : ${response.body}');
    }
  }

  // ♻️ Restaurer un achat supprimé
  static Future<void> restoreAchat(int achatId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$achatId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur restauration achat (${response.statusCode}) : ${response.body}');
    }
  }

  // 🔎 Recherche avancée avec filtres
  static Future<List<Achat>> searchAchats({
    String? libelle,
    String? fournisseur,
    double? montantMin,
    double? montantMax,
    String? dateAchat, // format "yyyy-MM-dd"
  }) async {
    final headers = await _getHeaders();

    final queryParameters = {
      if (libelle != null && libelle.isNotEmpty) 'libelle': libelle,
      if (fournisseur != null && fournisseur.isNotEmpty) 'fournisseur': fournisseur,
      if (montantMin != null) 'montant_min': montantMin.toString(),
      if (montantMax != null) 'montant_max': montantMax.toString(),
      if (dateAchat != null && dateAchat.isNotEmpty) 'date_achat': dateAchat,
    };

    final uri = Uri.parse('$base/search').replace(queryParameters: queryParameters);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Achat.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur recherche achats (${response.statusCode}) : ${response.body}');
    }
  }
}
