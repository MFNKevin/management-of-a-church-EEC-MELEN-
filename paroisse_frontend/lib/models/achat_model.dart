class Achat {
  final int achatId;
  final String libelle;
  final double montant;
  final DateTime dateAchat;
  final String? fournisseur;
  final DateTime? deletedAt;

  Achat({
    required this.achatId,
    required this.libelle,
    required this.montant,
    required this.dateAchat,
    this.fournisseur,
    this.deletedAt,
  });

  /// Crée une instance Achat à partir d'un JSON
  factory Achat.fromJson(Map<String, dynamic> json) {
    return Achat(
      achatId: json['achat_id'] as int,
      libelle: json['libelle'] as String,
      montant: (json['montant'] as num).toDouble(),
      dateAchat: DateTime.parse(json['date_achat'] as String),
      fournisseur: json['fournisseur'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Convertit l'objet Achat en JSON pour envoi vers API
  Map<String, dynamic> toJson() {
    return {
      // 'achat_id' est géré côté backend, donc pas envoyé ici
      'libelle': libelle,
      'montant': montant,
      // Envoi de la date au format ISO sans heure : yyyy-MM-dd
      'date_achat': dateAchat.toIso8601String().split('T')[0],
      'fournisseur': fournisseur,
    };
  }

  /// Copie l'objet Achat avec des modifications optionnelles
  Achat copyWith({
    int? achatId,
    String? libelle,
    double? montant,
    DateTime? dateAchat,
    String? fournisseur,
    DateTime? deletedAt,
  }) {
    return Achat(
      achatId: achatId ?? this.achatId,
      libelle: libelle ?? this.libelle,
      montant: montant ?? this.montant,
      dateAchat: dateAchat ?? this.dateAchat,
      fournisseur: fournisseur ?? this.fournisseur,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
