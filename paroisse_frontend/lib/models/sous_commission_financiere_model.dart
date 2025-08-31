class MembreSousCommission {
  final int membreSousCommissionId;
  final int sousCommissionId;
  final int utilisateurId;
  final String? role;

  // Ajouté : nom de la sous-commission (envoyé par le backend)
  final String? nomSousCommission;

  final String? nomUtilisateur;
  final String? prenomUtilisateur;

  MembreSousCommission({
    required this.membreSousCommissionId,
    required this.sousCommissionId,
    required this.utilisateurId,
    this.role,
    this.nomSousCommission,
    this.nomUtilisateur,
    this.prenomUtilisateur,
  });

  factory MembreSousCommission.fromJson(Map<String, dynamic> json) {
    return MembreSousCommission(
      membreSousCommissionId: json['membre_sous_commission_id'] as int,
      sousCommissionId: json['sous_commission_id'] as int,
      utilisateurId: json['utilisateur_id'] as int,
      role: json['role'] as String?,
      nomSousCommission: json['nom_sous_commission'] as String?,
      nomUtilisateur: json['nom_utilisateur'] as String?,
      prenomUtilisateur: json['prenom_utilisateur'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membre_sous_commission_id': membreSousCommissionId,
      'sous_commission_id': sousCommissionId,
      'utilisateur_id': utilisateurId,
      'role': role,
      'nom_sous_commission': nomSousCommission,
      'nom_utilisateur': nomUtilisateur,
      'prenom_utilisateur': prenomUtilisateur,
    };
  }
}

class SousCommissionFinanciere {
  final int sousCommissionId;
  final String nom;
  final String? description;

  SousCommissionFinanciere({
    required this.sousCommissionId,
    required this.nom,
    this.description,
  });

  factory SousCommissionFinanciere.fromJson(Map<String, dynamic> json) {
    return SousCommissionFinanciere(
      sousCommissionId: json['sous_commission_id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sous_commission_id': sousCommissionId,
      'nom': nom,
      'description': description,
    };
  }
}
