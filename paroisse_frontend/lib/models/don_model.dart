class Don {
  final int donId;
  final String donateur;
  final double montant;
  final DateTime dateDon;
  final String? commentaire;
  final String type;           // ajouté
  final int utilisateurId;     // ajouté
  final DateTime? deletedAt;
  final double? montantTotal; // champ calculé côté backend

  Don({
    required this.donId,
    required this.donateur,
    required this.montant,
    required this.dateDon,
    this.commentaire,
    required this.type,
    required this.utilisateurId,
    this.deletedAt,
    this.montantTotal,
  });

  factory Don.fromJson(Map<String, dynamic> json) => Don(
        donId: json['don_id'],
        donateur: json['donateur'],
        montant: (json['montant'] as num).toDouble(),
        dateDon: DateTime.parse(json['date_don']),
        commentaire: json['commentaire'],
        type: json['type'],
        utilisateurId: json['utilisateur_id'],
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        montantTotal: json['montant_total'] != null
            ? (json['montant_total'] as num).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'donateur': donateur,
        'montant': montant,
        'date_don': dateDon.toIso8601String().split('T')[0],
        if (commentaire != null) 'commentaire': commentaire,
        'type': type,
        'utilisateur_id': utilisateurId,
      };
}
