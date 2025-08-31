// lib/models/commission_financiere_model.dart

class MembreCommission {
  final int membreCommissionId;
  final int commissionId;
  final int utilisateurId;
  final String? role;

  final String? nomCommission;
  final String? nomUtilisateur;
  final String? prenomUtilisateur;

  MembreCommission({
    required this.membreCommissionId,
    required this.commissionId,
    required this.utilisateurId,
    this.role,
    this.nomCommission,
    this.nomUtilisateur,
    this.prenomUtilisateur,
  });

  factory MembreCommission.fromJson(Map<String, dynamic> json) {
    return MembreCommission(
      membreCommissionId: json['membre_commission_id'] as int,
      commissionId: json['commission_id'] as int,
      utilisateurId: json['utilisateur_id'] as int,
      role: json['role'] as String?,
      nomCommission: json['nom_commission'] as String?,
      nomUtilisateur: json['nom_utilisateur'] as String?,
      prenomUtilisateur: json['prenom_utilisateur'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membre_commission_id': membreCommissionId,
      'commission_id': commissionId,
      'utilisateur_id': utilisateurId,
      'role': role,
      'nom_commission': nomCommission,
      'nom_utilisateur': nomUtilisateur,
      'prenom_utilisateur': prenomUtilisateur,
    };
  }
}

class CommissionFinanciere {
  final int commissionId;
  final String nom;
  final String? description;

  CommissionFinanciere({
    required this.commissionId,
    required this.nom,
    this.description,
  });

  factory CommissionFinanciere.fromJson(Map<String, dynamic> json) {
    return CommissionFinanciere(
      commissionId: json['commission_id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commission_id': commissionId,
      'nom': nom,
      'description': description,
    };
  }
}
