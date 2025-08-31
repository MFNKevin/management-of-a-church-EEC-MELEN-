import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:paroisse_frontend/models/reunion_model.dart';
import 'package:paroisse_frontend/services/reunion_service.dart';

class ReunionDetailScreen extends StatefulWidget {
  final int reunionId;

  const ReunionDetailScreen({required this.reunionId, Key? key}) : super(key: key);

  @override
  State<ReunionDetailScreen> createState() => _ReunionDetailScreenState();
}

class _ReunionDetailScreenState extends State<ReunionDetailScreen> {
  late Future<Reunion> reunionFuture;

  @override
  void initState() {
    super.initState();
    reunionFuture = ReunionService.getReunionById(widget.reunionId);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la réunion')),
      body: FutureBuilder<Reunion>(
        future: reunionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Réunion non trouvée'));
          }

          final reunion = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Titre'),
                  subtitle: Text(reunion.titre),
                ),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(formatter.format(reunion.date)),
                ),
                ListTile(
                  title: const Text('Lieu'),
                  subtitle: Text(reunion.lieu?.isNotEmpty == true ? reunion.lieu! : '-'),
                ),
                ListTile(
                  title: const Text('Description'),
                  subtitle: Text(reunion.description?.isNotEmpty == true ? reunion.description! : '-'),
                ),
                ListTile(
                  title: const Text('Convocateur'),
                  subtitle: Text(reunion.convocateurRole.toString().split('.').last),
                ),

                if (reunion.convoques.isNotEmpty)
                  ListTile(
                    title: const Text('Convoqués'),
                    subtitle: Text(
                      reunion.convoques.join(', '), // Affichage simple des IDs, à améliorer si possible
                    ),
                  ),

                if (reunion.deletedAt != null)
                  ListTile(
                    title: const Text('Archivée le'),
                    subtitle: Text(formatter.format(reunion.deletedAt!)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
