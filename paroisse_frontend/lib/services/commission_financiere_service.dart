import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commission_financiere_model.dart';
import '../config.dart';
import '../utils/auth_token.dart';

class CommissionFinanciereService {
  // Correction ici : tiret au lieu de underscore dans le préfixe
  final String base = '${Config.baseUrl}/api/commission-financiere';

  // --- COMMISSION ---

  // Récupérer toutes les commissions, option d'inclure les supprimés
  Future<List<CommissionFinanciere>> fetchCommissions({bool includeDeleted = false}) async {
    final token = await AuthToken.getToken();
    final url = Uri.parse('$base/commissions?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => CommissionFinanciere.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement commissions: ${response.statusCode}');
    }
  }

  // Créer une commission
  Future<void> createCommission(CommissionFinanciere commission) async {
    final token = await AuthToken.getToken();
    final response = await http.post(
      Uri.parse('$base/commissions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(commission.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur création commission: ${response.statusCode}');
    }
  }

  // Mettre à jour une commission
  Future<void> updateCommission(CommissionFinanciere commission) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/commissions/${commission.commissionId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(commission.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour commission: ${response.statusCode}');
    }
  }

  // Suppression douce (soft delete) d'une commission
  Future<void> softDeleteCommission(int commissionId) async {
    final token = await AuthToken.getToken();
    final response = await http.delete(
      Uri.parse('$base/commissions/$commissionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression commission: ${response.statusCode}');
    }
  }

  // Restauration d'une commission supprimée
  Future<void> restoreCommission(int commissionId) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/commissions/restore/$commissionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur restauration commission: ${response.statusCode}');
    }
  }

  // --- MEMBRE COMMISSION ---

  // Récupérer tous les membres (toutes commissions)
  Future<List<MembreCommission>> fetchMembres({bool includeDeleted = false}) async {
    final token = await AuthToken.getToken();
    final url = Uri.parse('$base/membres_commission?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => MembreCommission.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement membres: ${response.statusCode}');
    }
  }

  // Récupérer les membres d'une commission spécifique
  Future<List<MembreCommission>> fetchMembresByCommission(int commissionId, {bool includeDeleted = false}) async {
    final token = await AuthToken.getToken();
    final url = Uri.parse('$base/commissions/$commissionId/membres?include_deleted=$includeDeleted');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => MembreCommission.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement membres commission: ${response.statusCode}');
    }
  }

  // Créer un membre commission
  Future<void> createMembre(MembreCommission membre) async {
    final token = await AuthToken.getToken();
    final response = await http.post(
      Uri.parse('$base/membres_commission'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(membre.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur création membre commission: ${response.statusCode}');
    }
  }

  // Mettre à jour un membre commission
  Future<void> updateMembre(MembreCommission membre) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/membres_commission/${membre.membreCommissionId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(membre.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour membre: ${response.statusCode}');
    }
  }

  // Suppression douce (soft delete) d'un membre commission
  Future<void> softDeleteMembre(int membreId) async {
    final token = await AuthToken.getToken();
    final response = await http.delete(
      Uri.parse('$base/membres_commission/$membreId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression membre: ${response.statusCode}');
    }
  }

  // Restauration d'un membre commission supprimé
  Future<void> restoreMembre(int membreId) async {
    final token = await AuthToken.getToken();
    final response = await http.put(
      Uri.parse('$base/membres_commission/restore/$membreId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur restauration membre: ${response.statusCode}');
    }
  }
}
