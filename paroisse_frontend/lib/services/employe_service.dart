import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paroisse_frontend/models/employe_model.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class EmployeService {
  static const String apiRoute = '/api/employes/';
  static String get base => '${Config.baseUrl}$apiRoute';

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

  static Future<List<Employe>> fetchEmployes({bool includeDeleted = false}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Employe.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement employés : ${response.body}');
    }
  }

  static Future<Employe> getEmployeById(int employeId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$base$employeId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Employe.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur récupération employé : ${response.body}');
    }
  }

  static Future<void> createEmploye(Employe employe) async {
    final headers = await _getHeaders();
    final body = employe.toJson(); // Contient déjà les bons formats
    final response = await http.post(
      Uri.parse(base),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur création employé : ${response.body}');
    }
  }

  static Future<void> updateEmploye(Employe employe) async {
    final headers = await _getHeaders();
    final body = employe.toJson(); // Peut contenir deleted_at aussi si nécessaire
    final response = await http.put(
      Uri.parse('$base${employe.employeId}'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour employé : ${response.body}');
    }
  }

  static Future<void> softDeleteEmploye(int employeId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$base$employeId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression employé : ${response.body}');
    }
  }

  static Future<void> restoreEmploye(int employeId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${base}restore/$employeId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur restauration employé : ${response.body}');
    }
  }
}
