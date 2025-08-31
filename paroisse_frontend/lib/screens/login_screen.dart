import 'package:flutter/material.dart';
import 'dart:convert';

import '../screens/home_screen.dart';
import '../services/auth_service.dart';
import '../utils/auth_token.dart'; // Pour stockage token + rôle + id
import '../main.dart'; // Pour AppColors

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) Appel login -> récupère token uniquement
      final response = await AuthService.login(email, password);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final token = data['access_token'] ?? '';

        if (token.isEmpty) {
          setState(() {
            _errorMessage = "Erreur : token manquant.";
            _isLoading = false;
          });
          return;
        }

        // Stocker token
        await AuthToken.setToken(token);

        // 2) Appel API pour récupérer infos utilisateur
        final userData = await AuthService.getCurrentUser();

        // DEBUG (optionnel)
        // print('User data: $userData');

        // Vérifier présence des champs attendus (id clé modifiée)
        if (userData == null || userData['role'] == null || userData['utilisateur_id'] == null) {
          setState(() {
            _errorMessage = "Erreur : données utilisateur incomplètes.";
            _isLoading = false;
          });
          return;
        }

        final role = userData['role'];
        final id = userData['utilisateur_id'];
        final nomComplet = userData['nomComplet'] ?? '';

        // Stocker infos utilisateur
        await AuthToken.setUserRole(role);
        await AuthToken.setUserId(id);
        // Si besoin, ajouter méthode setUserNomComplet dans AuthToken et décommenter:
        // await AuthToken.setUserNomComplet(nomComplet);

        if (!mounted) return;

        // Naviguer vers l'écran principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final data = json.decode(response.body);
        String message;

        if (data['detail'] is List) {
          message = (data['detail'] as List).map((e) => e.toString()).join('\n');
        } else if (data['detail'] is String) {
          message = data['detail'];
        } else {
          message = 'Erreur inconnue';
        }

        setState(() => _errorMessage = message);
      }
    } catch (e) {
      setState(() => _errorMessage = "Erreur réseau : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Connexion à la Paroisse",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Adresse email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "© 2025 EEC MELEN",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
