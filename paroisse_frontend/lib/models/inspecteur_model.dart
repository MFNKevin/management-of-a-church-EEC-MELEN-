class Inspecteur {
  final int inspecteurId;
  final String nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? fonction;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Inspecteur({
    required this.inspecteurId,
    required this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.fonction,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Crée une instance Inspecteur à partir d'un JSON
  factory Inspecteur.fromJson(Map<String, dynamic> json) {
    return Inspecteur(
      inspecteurId: json['inspecteur_id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      fonction: json['fonction'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Convertit l'objet Inspecteur en JSON pour envoi vers API
  Map<String, dynamic> toJson() {
    return {
      // 'inspecteur_id' géré côté backend, pas envoyé à la création
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'fonction': fonction,
      // createdAt, updatedAt, deletedAt ne sont pas envoyés au backend
    };
  }

  /// Copie l'objet Inspecteur avec des modifications optionnelles
  Inspecteur copyWith({
    int? inspecteurId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? fonction,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Inspecteur(
      inspecteurId: inspecteurId ?? this.inspecteurId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      fonction: fonction ?? this.fonction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
