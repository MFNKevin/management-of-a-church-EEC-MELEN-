// lib/constants/roles.dart

/// Liste complète des rôles disponibles dans l'application
class Roles {
  static const String administrateur = 'Administrateur';
  static const String commissionFinanciere = 'CommissionFinanciere';
  static const String evangeliste = 'Evangeliste';
  static const String fidele = 'Fidele';
  static const String inspecteur = 'Inspecteur';
  static const String pasteur = 'Pasteur';
  static const String responsableLaique = 'ResponsableLaique';
  static const String secretaire = 'Secretaire';
  static const String sousCommissionFinanciere = 'SousCommissionFinanciere';
  static const String tresorierParoissial = 'TresorierParoissial';
}

/// Rôles autorisés pour la gestion des Achats
class AchatRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Dons
class DonRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Offrandes
class OffrandeRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,    
  ];
}

/// Rôles autorisés pour la gestion des Quêtes
class QueteRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,    
  ];
}

/// Rôles autorisés pour la gestion des Reçus
class RecuRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Factures
class FactureRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Rapports
class RapportRoles {
  static const List<String> allowed = [
    Roles.administrateur,    
    Roles.inspecteur,
  ];
}

/// Rôles autorisés pour la gestion des Salaires
class SalaireRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Employés
class EmployeRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Utilisateurs
class UtilisateurRoles {
  static const List<String> allowed = [
    Roles.administrateur,
  ];
}

/// Rôles autorisés pour la gestion des Inspecteurs
class InspecteurRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
    Roles.inspecteur,
  ];
}

/// Rôles autorisés pour la gestion des Groupes
class GroupeRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Commissions Financières
class CommissionRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}

/// Rôles autorisés pour la gestion des Sous-Commissions Financières
class SousCommissionRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}


/// Rôles autorisés pour la gestion des Sous-Commissions Financières
class NotificationRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}


/// Rôles autorisés pour la gestion des Sous-Commissions Financières
class ReunionRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.pasteur,
    Roles.secretaire,
  ];
}


/// Rôles autorisés pour la gestion des Sous-Commissions Financières
class DecisionRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.responsableLaique,
    Roles.secretaire,
  ];
}

class BudgetRoles {
  static const List<String> allowed = [
    Roles.administrateur,
    Roles.tresorierParoissial,
  ];
}