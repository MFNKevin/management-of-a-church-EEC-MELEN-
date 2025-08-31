enum TypeNotificationEnum {
  info,
  success,
  warning,
  error,
  confirmation,
  question,
}

class NotificationModel {
  final int notificationId;
  final String titre;
  final String message;
  final TypeNotificationEnum type;
  final bool estLue;
  final bool emailEnvoye;
  final DateTime? emailEnvoyeAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int? utilisateurId;

  NotificationModel({
    required this.notificationId,
    required this.titre,
    required this.message,
    required this.type,
    required this.estLue,
    required this.emailEnvoye,
    this.emailEnvoyeAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.utilisateurId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'] as int,
      titre: json['titre'] as String,
      message: json['message'] as String,
      type: _typeFromString(json['type']),
      estLue: json['est_lue'] ?? false,
      emailEnvoye: json['email_envoye'] ?? false,
      emailEnvoyeAt: json['email_envoye_at'] != null
          ? DateTime.tryParse(json['email_envoye_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      utilisateurId: json['utilisateur_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'titre': titre,
      'message': message,
      'type': _typeToString(type),
      'est_lue': estLue,
      'email_envoye': emailEnvoye,
      'email_envoye_at': emailEnvoyeAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'utilisateur_id': utilisateurId,
    };
  }

  static TypeNotificationEnum _typeFromString(dynamic type) {
    if (type is! String) return TypeNotificationEnum.info;
    return TypeNotificationEnum.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TypeNotificationEnum.info,
    );
  }

  static String _typeToString(TypeNotificationEnum type) {
    return type.name;
  }
}
