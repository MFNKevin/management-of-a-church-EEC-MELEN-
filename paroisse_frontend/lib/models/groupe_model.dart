class Groupe {
  final int groupeId;
  final String nom;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Groupe({
    required this.groupeId,
    required this.nom,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Crée un objet Groupe depuis un JSON (reçu depuis l'API)
  factory Groupe.fromJson(Map<String, dynamic> json) {
    return Groupe(
      groupeId: json['groupe_id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Prépare les données à envoyer à l’API lors de la création ou mise à jour
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
    };
  }

  /// Création d’une copie modifiée de l’objet Groupe
  Groupe copyWith({
    int? groupeId,
    String? nom,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Groupe(
      groupeId: groupeId ?? this.groupeId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
