class Quete {
  final int queteId;
  final String libelle;
  final double montant;
  final DateTime dateQuete;
  final int utilisateurId;
  final DateTime? deletedAt;
  final double? montantTotal;

  Quete({
    required this.queteId,
    required this.libelle,
    required this.montant,
    required this.dateQuete,
    required this.utilisateurId,
    this.deletedAt,
    this.montantTotal,
  });

  factory Quete.fromJson(Map<String, dynamic> json) {
    return Quete(
      queteId: json['quete_id'],
      libelle: json['libelle'],
      montant: (json['montant'] as num).toDouble(),
      dateQuete: DateTime.parse(json['date_quete']),
      utilisateurId: json['utilisateur_id'],
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at']) : null,
      montantTotal: json['montant_total'] != null ? (json['montant_total'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'libelle': libelle,
      'montant': montant,
      'date_quete': dateQuete.toIso8601String().split('T')[0],
      'utilisateur_id': utilisateurId,
    };
  }

  Quete copyWith({
    int? queteId,
    String? libelle,
    double? montant,
    DateTime? dateQuete,
    int? utilisateurId,
    DateTime? deletedAt,
    double? montantTotal,
  }) {
    return Quete(
      queteId: queteId ?? this.queteId,
      libelle: libelle ?? this.libelle,
      montant: montant ?? this.montant,
      dateQuete: dateQuete ?? this.dateQuete,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      deletedAt: deletedAt ?? this.deletedAt,
      montantTotal: montantTotal ?? this.montantTotal,
    );
  }
}
