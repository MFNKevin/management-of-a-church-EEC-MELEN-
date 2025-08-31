import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/home_screen.dart'; // Vérifie que le chemin est correct

class HorizontalNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? nomComplet;
  final String? title;

  const HorizontalNavbar({super.key, this.nomComplet, this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title ?? "Bienvenue ${nomComplet ?? ''} 👋"),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Retour à l\'accueil',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
