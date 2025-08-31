import 'package:flutter/material.dart';
import 'vertical_sidebar.dart';
import 'horizontal_navbar.dart';

class ParoisseScaffold extends StatelessWidget {
  final Widget body;
  final String? nomComplet;
  final String? role;
  final String? photo;        // Photo utilisateur
  final VoidCallback onLogout;
  final String? title;
  final Widget? floatingActionButton;
  final String baseUrl;       // URL de base du backend (ex: http://127.0.0.1:8000)

  const ParoisseScaffold({
    super.key,
    required this.body,
    required this.onLogout,
    required this.baseUrl,
    this.nomComplet,
    this.role,
    this.photo,
    this.title,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: VerticalSidebar(
        nom: nomComplet,
        role: role,
        photo: photo,
        onLogout: onLogout,
        baseUrl: baseUrl,
      ),
      appBar: HorizontalNavbar(
        nomComplet: nomComplet,
        title: title,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
