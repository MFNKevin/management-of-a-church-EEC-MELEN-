import 'package:flutter/material.dart';

// 📱 Authentification & profil
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/utilisateur_screen.dart';

// 🔹 Recettes
import 'screens/don_screen.dart';
import 'screens/offrande_screen.dart';
import 'screens/quete_screen.dart';
import 'screens/recu_screen.dart';
import 'screens/recette_global_screen.dart';

// 🔸 Dépenses
import 'screens/achat_screen.dart';
import 'screens/facture_screen.dart';
import 'screens/depense_global_screen.dart';
import 'screens/salaire_screen.dart';

// 💰 Budget & rapports financiers
import 'screens/budget_screen.dart';
import 'screens/rapport_financier_screen.dart';

// 🧑‍⚖️ Gestion administrative
import 'screens/employe_screen.dart';
import 'screens/reunion_screen.dart';
import 'screens/decision_screen.dart';
import 'screens/rapport_administratif_screen.dart';

// 🔔 Notifications & chatbot
import 'screens/notification_screen.dart';
import 'screens/chatbot_screen.dart';

// 🏗️ Infrastructures & matériels
import 'screens/materiel_screen.dart';
import 'screens/infrastructure_screen.dart';
import 'screens/maintenance_screen.dart';


// 🧑‍💼 Commissions & sous-commissions
import 'screens/commission_financiere_screen.dart';
import 'screens/sous_commission_financiere_screen.dart';
import 'screens/inspecteur_screen.dart';

// Ajout de l'écran Groupe (à créer si nécessaire)
import 'screens/groupe_screen.dart';

// 🎨 Couleurs de l’application
class AppColors {
  static const Color primary = Color(0xFF2C3E9E);     // Bleu roi
  static const Color background = Color(0xFFEAF2FF);  // Bleu clair
  static const Color accent = Color(0xFFFFD700);      // Doré
  static const Color text = Color(0xFF1C1C1C);         // Sombre neutre
  static const Color error = Color(0xFFA93226);        // Rouge vin

  // Tons complémentaires
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color green = Color(0xFF27AE60);
  static const Color red = Color(0xFFE74C3C);
  static const Color yellow = Color(0xFFF4D03F);
  static const Color brown = Color(0xFF8B5E3C);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paroisse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.error,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        // 🔐 Authentification
        '/login': (_) => const LoginScreen(),
        '/profil': (_) => const ProfileScreen(),
        '/utilisateurs': (_) => const UtilisateurScreen(),

        // 🔹 Recettes
        '/dons': (_) => const DonScreen(),
        '/offrandes': (_) => const OffrandeScreen(),
        '/quetes': (_) => const QueteScreen(),
        '/recus': (_) => const RecuScreen(),
        '/recettes': (_) => const RecetteGlobalScreen(),

        // 🔸 Dépenses
        '/achats': (_) => const AchatScreen(),
        '/factures': (_) => const FactureScreen(),
        '/depenses': (_) => const DepenseGlobalScreen(),
        '/salaires': (_) => const SalaireScreen(),

        // 💰 Budget & finances
        '/budgets': (_) => const BudgetScreen(),
        '/rapports-financiers': (_) => const RapportFinancierScreen(),

        // 🧑‍⚖️ Gestion administrative
        '/employes': (_) => const EmployeScreen(),
        '/reunions': (_) => const ReunionScreen(),
        '/decisions': (_) => const DecisionScreen(),
        '/rapports-administratifs': (_) => const RapportAdministratifScreen(),

        // 🔔 Notifications & chatbot
        '/notifications': (_) => const NotificationsScreen(),
        '/chatbot': (_) => const ChatbotScreen(),

        // 🏗️ Infrastructures & matériels
        '/materiels': (_) => const MaterielScreen(),
        '/infrastructures': (_) => const InfrastructureScreen(),
        '/maintenances': (_) => const MaintenanceScreen(),

        // 🧑‍💼 Commissions & inspecteurs
        '/commissions': (_) => const CommissionFinanciereScreen(),     
        '/sous-commissions': (_) => const SousCommissionFinanciereScreen(),        
        '/inspecteurs': (_) => const InspecteurScreen(),

        // Groupe
        '/groupes': (_) => const GroupeScreen(),

        // Note : la route '/conseil-paroissial' a été supprimée
      },
    );
  }
}
