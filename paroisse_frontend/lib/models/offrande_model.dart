class Offrande {
  final int offrandeId;
  final double montant;
  final DateTime date; // correspond à "date" côté backend
  final String? description;
  final String type;
  final int? utilisateurId;
  final DateTime? deletedAt;

  Offrande({
    required this.offrandeId,
    required this.montant,
    required this.date,
    this.description,
    required this.type,
    this.utilisateurId,
    this.deletedAt,
  });

  factory Offrande.fromJson(Map<String, dynamic> json) => Offrande(
        offrandeId: json['offrande_id'],
        montant: (json['montant'] as num).toDouble(),
        date: DateTime.parse(json['date']),  // clé "date" cohérente avec alias Pydantic
        description: json['description'],
        type: json['type'],
        utilisateurId: json['utilisateur_id'],
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'montant': montant,
        'date': date.toIso8601String().split('T')[0], // format YYYY-MM-DD
        if (description != null) 'description': description,
        'type': type,
        if (utilisateurId != null) 'utilisateur_id': utilisateurId,
        // 'deleted_at' n'est pas envoyé car c'est géré côté backend
      };
}
