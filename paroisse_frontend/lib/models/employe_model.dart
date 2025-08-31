class Employe {
  final int employeId;
  final String nom;
  final String? prenom;
  final String? poste;
  final DateTime? dateNaissance;
  final DateTime? dateEmbauche;
  final double salaire;
  final int? groupeId;
  final DateTime? deletedAt;

  Employe({
    required this.employeId,
    required this.nom,
    this.prenom,
    this.poste,
    this.dateNaissance,
    this.dateEmbauche,
    required this.salaire,
    this.groupeId,
    this.deletedAt,
  });

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
      employeId: json['employe_id'],
      nom: json['nom'],
      prenom: json['prenom'],
      poste: json['poste'],
      dateNaissance: json['date_naissance'] != null
          ? DateTime.parse(json['date_naissance'])
          : null,
      dateEmbauche: json['date_embauche'] != null
          ? DateTime.parse(json['date_embauche'])
          : null,
      salaire: (json['salaire'] as num?)?.toDouble() ?? 0.0,
      groupeId: json['groupe_id'],
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employe_id': employeId,
      'nom': nom,
      'prenom': prenom,
      'poste': poste,
      'date_naissance': dateNaissance?.toIso8601String().split('T')[0],
      'date_embauche': dateEmbauche?.toIso8601String().split('T')[0],
      'salaire': salaire,
      'groupe_id': groupeId,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Employe copyWith({
    int? employeId,
    String? nom,
    String? prenom,
    String? poste,
    DateTime? dateNaissance,
    DateTime? dateEmbauche,
    double? salaire,
    int? groupeId,
    DateTime? deletedAt,
  }) {
    return Employe(
      employeId: employeId ?? this.employeId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      poste: poste ?? this.poste,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      salaire: salaire ?? this.salaire,
      groupeId: groupeId ?? this.groupeId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
