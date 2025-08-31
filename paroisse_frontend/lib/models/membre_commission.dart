import 'roles.dart'; // où tu définiras l’enum RoleCommission

class MembreCommission {
  final int membreCommissionId;
  final int commissionId;
  final int utilisateurId;
  final RoleCommission role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  MembreCommission({
    required this.membreCommissionId,
    required this.commissionId,
    required this.utilisateurId,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Crée une instance MembreCommission à partir d'un JSON
  factory MembreCommission.fromJson(Map<String, dynamic> json) {
    return MembreCommission(
      membreCommissionId: json['membre_commission_id'] as int,
      commissionId: json['commission_id'] as int,
      utilisateurId: json['utilisateur_id'] as int,
      role: RoleCommissionExtension.fromString(json['role'] ?? 'membre'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Convertit l'objet en JSON pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      'commission_id': commissionId,
      'utilisateur_id': utilisateurId,
      'role': role.value,
      // Pas besoin d'envoyer membreCommissionId, createdAt, updatedAt, deletedAt
    };
  }

  /// Copie l'objet avec modifications optionnelles
  MembreCommission copyWith({
    int? membreCommissionId,
    int? commissionId,
    int? utilisateurId,
    RoleCommission? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MembreCommission(
      membreCommissionId: membreCommissionId ?? this.membreCommissionId,
      commissionId: commissionId ?? this.commissionId,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Vérifie si le membre est supprimé (soft delete)
  bool get estSupprime => deletedAt != null;
}
