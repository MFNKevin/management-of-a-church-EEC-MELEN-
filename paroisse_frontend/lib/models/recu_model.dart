class Recu {
  final int recuId;
  final DateTime dateEmission;
  final double montant;
  final String? description;
  final int utilisateurId;
  final DateTime? deletedAt;
  final double? montantTotal;

  Recu({
    required this.recuId,
    required this.dateEmission,
    required this.montant,
    this.description,
    required this.utilisateurId,
    this.deletedAt,
    this.montantTotal,
  });

  factory Recu.fromJson(Map<String, dynamic> json) {
    return Recu(
      recuId: json['recu_id'] as int,
      dateEmission: DateTime.parse(json['date_emission']),
      montant: (json['montant'] as num).toDouble(),
      description: json['description'],
      utilisateurId: json['utilisateur_id'] as int,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      montantTotal: json['montant_total'] != null
          ? (json['montant_total'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_emission': dateEmission.toIso8601String(),
      'montant': montant,
      'description': description,
      'utilisateur_id': utilisateurId,
    };
  }

  Recu copyWith({
    int? recuId,
    DateTime? dateEmission,
    double? montant,
    String? description,
    int? utilisateurId,
    DateTime? deletedAt,
    double? montantTotal,
  }) {
    return Recu(
      recuId: recuId ?? this.recuId,
      dateEmission: dateEmission ?? this.dateEmission,
      montant: montant ?? this.montant,
      description: description ?? this.description,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      deletedAt: deletedAt ?? this.deletedAt,
      montantTotal: montantTotal ?? this.montantTotal,
    );
  }
}
