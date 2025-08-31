class Salaire {
  final int salaireId;            // correspond à salaire_id en base
  final double montant;
  final DateTime datePaiement;    // date_paiement
  final int employeId;            // employe_id
  final int utilisateurId;        // utilisateur_id (non nullable d’après SQLAlchemy)
  final DateTime createdAt;       // created_at (utile côté frontend)
  final DateTime? deletedAt;      // nullable pour soft delete

  final String? employeNom;
  final String? employePrenom;
  final String? poste;            // employe_poste

  Salaire({
    required this.salaireId,
    required this.montant,
    required this.datePaiement,
    required this.employeId,
    required this.utilisateurId,
    required this.createdAt,
    this.deletedAt,
    this.employeNom,
    this.employePrenom,
    this.poste,
  });

  factory Salaire.fromJson(Map<String, dynamic> json) {
    return Salaire(
      salaireId: json['salaire_id'],
      montant: (json['montant'] as num).toDouble(),
      datePaiement: DateTime.parse(json['date_paiement']),
      employeId: json['employe_id'],
      utilisateurId: json['utilisateur_id'],
      createdAt: DateTime.parse(json['created_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      employeNom: json['employe_nom'],
      employePrenom: json['employe_prenom'],
      poste: json['employe_poste'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'montant': montant,
      'date_paiement': datePaiement.toIso8601String().split('T')[0],
      'employe_id': employeId,
      'utilisateur_id': utilisateurId,
      // 'deleted_at' non envoyé, backend gère soft delete
    };
  }
}
