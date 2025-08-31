class Budget {
  final int budgetId;
  final String intitule;
  final int annee;
  final double montantTotal;
  final double? montantApprouve;
  final String? statut;
  final DateTime dateSoumission;
  final int utilisateurId;
  final int? commissionfinanciereId;
  final int? souscommissionfinanciereId;
  final String sousCategorie;
  final String categorie;
  final double montantReel;
  final DateTime? deletedAt;

  Budget({
    required this.budgetId,
    required this.intitule,
    required this.annee,
    required this.montantTotal,
    this.montantApprouve,
    this.statut,
    required this.dateSoumission,
    required this.utilisateurId,
    this.commissionfinanciereId,
    this.souscommissionfinanciereId,
    required this.sousCategorie,
    required this.categorie,
    required this.montantReel,
    this.deletedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        budgetId: json['budget_id'] ?? 0,
        intitule: json['intitule'] ?? '',
        annee: json['annee'] ?? 0,
        montantTotal: (json['montantTotal'] ?? 0).toDouble(),
        montantApprouve: json['montantApprouve'] != null
            ? (json['montantApprouve'] as num).toDouble()
            : null,
        statut: json['statut'],
        dateSoumission: DateTime.tryParse(json['dateSoumission'] ?? '') ??
            DateTime.now(),
        utilisateurId: json['utilisateur_id'] ?? 0,
        commissionfinanciereId: json['commissionfinanciere_id'],
        souscommissionfinanciereId: json['souscommissionfinanciere_id'],
        sousCategorie: json['sous_categorie'] ?? '',
        categorie: json['categorie'] ?? '',
        montantReel: (json['montant_reel'] ?? 0).toDouble(),
        deletedAt: json['deleted_at'] != null
            ? DateTime.tryParse(json['deleted_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'intitule': intitule,
        'annee': annee,
        'montantTotal': montantTotal,
        if (montantApprouve != null) 'montantApprouve': montantApprouve,
        if (statut != null) 'statut': statut,
        'utilisateur_id': utilisateurId,
        if (commissionfinanciereId != null)
          'commissionfinanciere_id': commissionfinanciereId,
        if (souscommissionfinanciereId != null)
          'souscommissionfinanciere_id': souscommissionfinanciereId,
        'sous_categorie': sousCategorie,
        'categorie': categorie,
        // montant_reel est calculé côté backend, donc non envoyé ici
      };
}
