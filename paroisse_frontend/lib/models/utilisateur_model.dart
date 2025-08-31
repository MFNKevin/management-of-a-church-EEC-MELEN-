enum RoleEnum {
  TresorierParoissial,
  Evangeliste,
  Administrateur,
  Fidele,
  Pasteur,
  Inspecteur,
  ResponsableLaique,
  Secretaire,
  SousCommissionFinanciere,
  CommissionFinanciere,
}

class Utilisateur {
  final int utilisateurId;
  final String? photo;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? profession;
  final String? villeResidence;
  final String? nationalite;
  final String? lieuNaissance;
  final String? etatCivil;
  final String? sexe;
  final DateTime? dateNaissance;
  final RoleEnum role;
  final DateTime? deletedAt;

  // Champ mot de passe pour la création
  final String? password;

  Utilisateur({
    required this.utilisateurId,
    this.photo,
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.profession,
    this.villeResidence,
    this.nationalite,
    this.lieuNaissance,
    this.etatCivil,
    this.sexe,
    this.dateNaissance,
    required this.role,
    this.deletedAt,
    this.password,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    String? roleString = json['role'] ?? json['roleEnum'] ?? '';

    return Utilisateur(
      utilisateurId: json['utilisateur_id'] ?? 0,
      photo: json['photo'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      profession: json['profession'],
      villeResidence: json['villeResidence'] ?? json['ville_residence'],
      nationalite: json['nationalite'],
      lieuNaissance: json['lieuNaissance'] ?? json['lieu_naissance'],
      etatCivil: json['etatCivil'] ?? json['etat_civil'],
      sexe: json['sexe'],
      dateNaissance: json['dateNaissance'] != null
          ? DateTime.tryParse(json['dateNaissance'])
          : null,
      role: RoleEnum.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (roleString?.toLowerCase() ?? ''),
        orElse: () => RoleEnum.Fidele,
      ),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      password: json['password'], // facultatif en lecture
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'utilisateur_id': utilisateurId,
      'photo': photo,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'profession': profession,
      'villeResidence': villeResidence,
      'nationalite': nationalite,
      'lieuNaissance': lieuNaissance,
      'etatCivil': etatCivil,
      'sexe': sexe,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'role': role.name,
      'deleted_at': deletedAt?.toIso8601String(),
    };

    if (password != null) {
      data['mot_de_passe'] = password;  // << clé correcte pour le backend
    }

    return data;
  }

  bool get isDeleted => deletedAt != null;

  Utilisateur copyWith({
    int? utilisateurId,
    String? photo,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? profession,
    String? villeResidence,
    String? nationalite,
    String? lieuNaissance,
    String? etatCivil,
    String? sexe,
    DateTime? dateNaissance,
    RoleEnum? role,
    DateTime? deletedAt,
    String? password,
  }) {
    return Utilisateur(
      utilisateurId: utilisateurId ?? this.utilisateurId,
      photo: photo ?? this.photo,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      profession: profession ?? this.profession,
      villeResidence: villeResidence ?? this.villeResidence,
      nationalite: nationalite ?? this.nationalite,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      etatCivil: etatCivil ?? this.etatCivil,
      sexe: sexe ?? this.sexe,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      role: role ?? this.role,
      deletedAt: deletedAt ?? this.deletedAt,
      password: password ?? this.password,
    );
  }
}
