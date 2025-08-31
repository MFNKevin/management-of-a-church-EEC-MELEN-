class Decision {
  final int decisionId;
  final String titre;
  final String? description;
  final int reunionId;
  final int auteurId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dateValide;
  final DateTime? deletedAt;

  // Champs liés
  final String? titreReunion;
  final String? nomAuteur;
  final String? prenomAuteur;

  Decision({
    required this.decisionId,
    required this.titre,
    this.description,
    required this.reunionId,
    required this.auteurId,
    required this.createdAt,
    this.updatedAt,
    this.dateValide,
    this.deletedAt,
    this.titreReunion,
    this.nomAuteur,
    this.prenomAuteur,
  });

  factory Decision.fromJson(Map<String, dynamic> json) => Decision(
        decisionId: json['decision_id'],
        titre: json['titre'],
        description: json['description'],
        reunionId: json['reunion_id'],
        auteurId: json['auteur_id'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        dateValide: json['date_valide'] != null
            ? DateTime.parse(json['date_valide'])
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
        titreReunion: json['titre_reunion'],
        nomAuteur: json['nom_auteur'],
        prenomAuteur: json['prenom_auteur'],
      );

  Map<String, dynamic> toJson() => {
        'titre': titre,
        if (description != null) 'description': description,
        'reunion_id': reunionId,
        'auteur_id': auteurId,
        if (dateValide != null)
          'date_valide': dateValide!.toIso8601String(),
      };
}
