import 'package:flutter/material.dart';
import 'package:paroisse_frontend/screens/corbeille_screen.dart';

class VerticalSidebar extends StatelessWidget {
  final String? role;
  final String? nom;
  final String? photo;
  final String baseUrl;
  final VoidCallback onLogout;

  const VerticalSidebar({
    super.key,
    required this.role,
    required this.nom,
    required this.onLogout,
    required this.baseUrl,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (photo != null && photo!.isNotEmpty) {
      avatarImage = NetworkImage('$baseUrl/$photo');
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(nom ?? ''),
            accountEmail: Text(role ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, color: Colors.black)
                  : null,
            ),
            decoration: const BoxDecoration(color: Color(0xFF2C3E9E)),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.account_balance),
            title: const Text("Gestion financière"),
            children: [
              ExpansionTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text("Recettes"),
                children: [
                  _buildNavTile(context, "Dons", '/dons'),
                  _buildNavTile(context, "Offrandes", '/offrandes'),
                  _buildNavTile(context, "Quêtes", '/quetes'),
                  _buildNavTile(context, "Reçus", '/recus'),
                  const Divider(),
                  _buildNavTile(context, "Toutes les Recettes", '/recettes'),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text("Dépenses"),
                children: [
                  _buildNavTile(context, "Achats", '/achats'),
                  _buildNavTile(context, "Factures", '/factures'),
                  _buildNavTile(context, "Salaires", '/salaires'),
                  const Divider(),
                  _buildNavTile(context, "Toutes les Dépenses", '/depenses'),
                ],
              ),
              _buildNavTile(context, "Budgets", '/budgets'),
              _buildNavTile(context, "Rapports Financiers", '/rapports-financiers'),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text("Gestion administrative"),
            children: [
              _buildNavTile(context, "Réunions", '/reunions'),
              _buildNavTile(context, "Décisions", '/decisions'),
              _buildNavTile(context, "Rapports Administratifs", '/rapports-administratifs'),           
            
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.people),
            title: const Text("Gestion du personnel"),
            children: [
              _buildNavTile(context, "Employés", '/employes'),
              _buildNavTile(context, "Utilisateurs", '/utilisateurs'),
              _buildNavTile(context, "Inspecteurs", '/inspecteurs'),
              _buildNavTile(context, "Groupes", '/groupes'),
              _buildNavTile(context, "Commissions financières", '/commissions'),
              _buildNavTile(context, "Sous-commissions", '/sous-commissions'),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.home_repair_service),
            title: const Text("Gestion infrastructurelle"),
            children: [
              _buildNavTile(context, "Matériels", '/materiels'),
              _buildNavTile(context, "Infrastructures", '/infrastructures'),
              _buildNavTile(context, "Maintenances", '/maintenances'),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Système"),
            children: [
              _buildNavTile(context, "Notifications", '/notifications'),
              _buildNavTile(context, "Chatbot", '/chatbot'),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text("Corbeille globale"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CorbeilleScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Mon profil"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profil');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Se déconnecter"),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  ListTile _buildNavTile(BuildContext context, String title, String routeName) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
