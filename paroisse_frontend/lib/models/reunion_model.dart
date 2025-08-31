// reunion_model.dart

import 'dart:convert';

enum ConvocateurEnum {
  Pasteur,
  Evangeliste,
  ResponsableLaique,
  Secretaire,
  Fidele,
}

ConvocateurEnum parseConvocateurRole(String? value) {
  return ConvocateurEnum.values.firstWhere(
    (e) => e.name.toLowerCase() == value?.toLowerCase(),
    orElse: () => ConvocateurEnum.Fidele,
  );
}

class Reunion {
  final int reunionId;
  final String titre;
  final DateTime date;
  final String? lieu;
  final String? description;
  final ConvocateurEnum convocateurRole;
  final List<int> convoques;  // non nullable
  final DateTime? deletedAt;

  Reunion({
    required this.reunionId,
    required this.titre,
    required this.date,
    this.lieu,
    this.description,
    required this.convocateurRole,
    required this.convoques,   // non nullable & required
    this.deletedAt,
  });

  factory Reunion.fromJson(Map<String, dynamic> json) {
    return Reunion(
      reunionId: json['reunion_id'] as int,
      titre: json['titre'] as String,
      date: DateTime.parse(json['date']),
      lieu: json['lieu'],
      description: json['description'],
      convocateurRole: parseConvocateurRole(json['convocateur_role']),
      convoques: (json['convoques'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],  // toujours une liste, jamais null
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'date': date.toIso8601String(),
      'lieu': lieu,
      'description': description,
      'convocateur_role': convocateurRole.name,
      'convoques': convoques,  // direct, sans map
    };
  }

  Reunion copyWith({
    int? reunionId,
    String? titre,
    DateTime? date,
    String? lieu,
    String? description,
    ConvocateurEnum? convocateurRole,
    List<int>? convoques,
    DateTime? deletedAt,
  }) {
    return Reunion(
      reunionId: reunionId ?? this.reunionId,
      titre: titre ?? this.titre,
      date: date ?? this.date,
      lieu: lieu ?? this.lieu,
      description: description ?? this.description,
      convocateurRole: convocateurRole ?? this.convocateurRole,
      convoques: convoques ?? this.convoques,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
