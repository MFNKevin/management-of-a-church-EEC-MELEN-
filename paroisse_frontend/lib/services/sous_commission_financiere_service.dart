import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sous_commission_financiere_model.dart';
import '../config.dart';
import '../utils/auth_token.dart';

class SousCommissionFinanciereService {
  final String base = '${Config.baseUrl}/api/sous-commission-financiere';

  // --- SOUS-COMMISSION ---

  Future<List<SousCommissionFinanciere>> fetchSousCommissions({bool includeDeleted = false}) async {
    final token = await AuthToken.getToken();
    final url = Uri.parse('$base/?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => SousCommissionFinanciere.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement sous-commissions: ${response.statusCode}');
    }
  }

  Future<void> createSousCommission(SousCommissionFinanciere sousCommission) async {
    final token = await AuthToken.getToken();
    final response = await http.post(
      Uri.parse('$base/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(sousCommission.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur création sous-commission: ${response.statusCode}');
    }
  }

  Future<void> updateSousCommission(SousCommissionFinanciere sousCommission) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/${sousCommission.sousCommissionId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(sousCommission.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour sous-commission: ${response.statusCode}');
    }
  }

  Future<void> softDeleteSousCommission(int sousCommissionId) async {
    final token = await AuthToken.getToken();
    final response = await http.delete(
      Uri.parse('$base/$sousCommissionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression sous-commission: ${response.statusCode}');
    }
  }

  Future<void> restoreSousCommission(int sousCommissionId) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/restore/$sousCommissionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur restauration sous-commission: ${response.statusCode}');
    }
  }

  // --- MEMBRES SOUS-COMMISSION ---

  // Suppression de la méthode fetchMembres() sans paramètre car la route backend n'existe pas

  Future<List<MembreSousCommission>> fetchMembresBySousCommission(int sousCommissionId, {bool includeDeleted = false}) async {
    final token = await AuthToken.getToken();
    final url = Uri.parse('$base/$sousCommissionId/membres?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => MembreSousCommission.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement membres sous-commission: ${response.statusCode}');
    }
  }

  Future<void> createMembre(MembreSousCommission membre) async {
    final token = await AuthToken.getToken();
    final response = await http.post(
      Uri.parse('$base/membres'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // nomSousCommission ne sera pas envoyé car il est rempli côté backend
      body: json.encode(membre.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur création membre sous-commission: ${response.statusCode}');
    }
  }

  Future<void> updateMembre(MembreSousCommission membre) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/membres/${membre.membreSousCommissionId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(membre.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour membre sous-commission: ${response.statusCode}');
    }
  }

  Future<void> softDeleteMembre(int membreId) async {
    final token = await AuthToken.getToken();
    final response = await http.delete(
      Uri.parse('$base/membres/$membreId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression membre sous-commission: ${response.statusCode}');
    }
  }

  Future<void> restoreMembre(int membreId) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/membres/restore/$membreId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur restauration membre sous-commission: ${response.statusCode}');
    }
  }
}
