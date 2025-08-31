class Facture {
  final int factureId;
  final String numero;
  final double montant;
  final DateTime dateFacture;
  final String? description;
  final int utilisateurId;
  final DateTime? deletedAt;
  final double? montantTotal;

  Facture({
    required this.factureId,
    required this.numero,
    required this.montant,
    required this.dateFacture,
    this.description,
    required this.utilisateurId,
    this.deletedAt,
    this.montantTotal,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      factureId: json['facture_id'],
      numero: json['numero'],
      montant: (json['montant'] as num).toDouble(),
      dateFacture: DateTime.parse(json['date_facture']),
      description: json['description'],
      utilisateurId: json['utilisateur_id'],
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at']) : null,
      montantTotal: json['montant_total'] != null ? (json['montant_total'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'montant': montant,
      'date_facture': dateFacture.toIso8601String().split('T')[0],
      'description': description,
      'utilisateur_id': utilisateurId,
    };
  }

  Facture copyWith({
    int? factureId,
    String? numero,
    double? montant,
    DateTime? dateFacture,
    String? description,
    int? utilisateurId,
    DateTime? deletedAt,
    double? montantTotal,
  }) {
    return Facture(
      factureId: factureId ?? this.factureId,
      numero: numero ?? this.numero,
      montant: montant ?? this.montant,
      dateFacture: dateFacture ?? this.dateFacture,
      description: description ?? this.description,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      deletedAt: deletedAt ?? this.deletedAt,
      montantTotal: montantTotal ?? this.montantTotal,
    );
  }
}
