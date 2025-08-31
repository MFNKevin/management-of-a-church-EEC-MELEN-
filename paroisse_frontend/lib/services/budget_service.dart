import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/budget_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class BudgetService {
  static const String apiRoute = '/api/budgets/';
  static String get base => '${Config.baseUrl}$apiRoute';

  /// Génère les headers avec token d’authentification
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

  /// Liste paginée des budgets
  static Future<List<Budget>> fetchBudgets({
    int skip = 0,
    int limit = 10,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
        '$base?skip=$skip&limit=$limit&include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((e) => Budget.fromJson(e)).toList();
      }
      throw Exception('Format de réponse invalide pour fetchBudgets.');
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
          'Erreur chargement budgets (${response.statusCode}) : ${response.body}');
    }
  }

  /// Détail budget par ID
  static Future<Budget> fetchBudgetById(
    int budgetId, {
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$budgetId?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Budget.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
          'Budget introuvable (${response.statusCode}) : ${response.body}');
    }
  }

  /// Créer un nouveau budget
  static Future<void> createBudget(Budget budget) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(budget.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
          'Erreur création budget (${response.statusCode}) : ${response.body}');
    }
  }

  /// Mise à jour budget
  static Future<void> updateBudget(Budget budget) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base${budget.budgetId}');
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(budget.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
          'Erreur mise à jour budget (${response.statusCode}) : ${response.body}');
    }
  }

  /// Suppression logique (soft delete)
  static Future<void> softDeleteBudget(int budgetId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$budgetId');
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
          'Erreur suppression budget (${response.statusCode}) : ${response.body}');
    }
  }

  /// Restaurer un budget supprimé
  static Future<void> restoreBudget(int budgetId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${base}restore/$budgetId');
    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception(
          'Erreur restauration budget (${response.statusCode}) : ${response.body}');
    }
  }

  /// Recherche budgets par critères
  static Future<List<Budget>> searchBudgets({
    String? intitule,
    int? annee,
    String? statut,
    String? categorie,
    String? sousCategorie,
    int? utilisateurId,
    bool includeDeleted = false,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (intitule != null && intitule.isNotEmpty) {
      queryParams['intitule'] = intitule;
    }
    if (annee != null) queryParams['annee'] = annee.toString();
    if (statut != null && statut.isNotEmpty) queryParams['statut'] = statut;
    if (categorie != null && categorie.isNotEmpty) {
      queryParams['categorie'] = categorie;
    }
    if (sousCategorie != null && sousCategorie.isNotEmpty) {
      queryParams['sous_categorie'] = sousCategorie;
    }
    if (utilisateurId != null) {
      queryParams['utilisateur_id'] = utilisateurId.toString();
    }
    queryParams['include_deleted'] = includeDeleted.toString();

    final uri =
        Uri.parse('${base}search').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((e) => Budget.fromJson(e)).toList();
      }
      throw Exception('Format de réponse invalide pour searchBudgets.');
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
          'Erreur recherche budgets (${response.statusCode}) : ${response.body}');
    }
  }
}
