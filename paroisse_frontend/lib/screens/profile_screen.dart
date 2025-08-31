import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../main.dart'; // AppColors
import '../config.dart'; // Config globale
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data = await AuthService.getCurrentUser();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur de chargement du profil : $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');  // Suppression du token
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasError || userData == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Erreur de chargement du profil.",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    final nom = userData?['nom'] ?? '';
    final prenom = userData?['prenom'] ?? '';
    final role = userData?['role'] ?? '';
    final photo = userData?['photo'];

    ImageProvider? avatarImage;
    if (photo != null && photo.toString().isNotEmpty) {
      final imageUrl = "${Config.baseUrl}/${photo.toString()}"; // Utilisation de Config.baseUrl
      avatarImage = NetworkImage(imageUrl);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            (prenom.isNotEmpty ? prenom[0] : '') +
                                (nom.isNotEmpty ? nom[0] : ''),
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "$prenom $nom",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const Divider(height: 30, thickness: 1.2),

                infoRow("Nom", nom),
                infoRow("Prénom", prenom),
                infoRow("Date de naissance", formatDate(userData?['dateNaissance']?.toString())),
                infoRow("Lieu de naissance", userData?['lieuNaissance'] ?? ''),
                infoRow("Nationalité", userData?['nationalite'] ?? ''),
                infoRow("Ville de résidence", userData?['villeResidence'] ?? ''),
                infoRow("Email", userData?['email'] ?? ''),
                infoRow("Profession", userData?['profession'] ?? ''),
                infoRow("Téléphone", userData?['telephone'] ?? ''),
                infoRow("État civil", userData?['etatCivil'] ?? ''),
                infoRow("Sexe", userData?['sexe'] ?? ''),
                infoRow("Rôle", role),
                infoRow("ID utilisateur", userData?['utilisateur_id']?.toString() ?? ''),
                infoRow("Supprimé le", userData?['deleted_at']?.toString() ?? ''),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Modifier Profil"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(userData: userData!),
                            ),
                          );
                          if (result == true) {
                            _loadUser(); // Recharge après modification
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Déconnexion"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _onLogout,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
