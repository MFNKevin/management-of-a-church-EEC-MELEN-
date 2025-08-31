import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../main.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late TextEditingController telephoneController;
  late TextEditingController professionController;
  late TextEditingController villeController;
  late TextEditingController nationaliteController;
  late TextEditingController lieuNaissanceController;
  late TextEditingController photoController;

  String? selectedSexe;
  String? selectedEtatCivil;

  DateTime? dateNaissance;
  File? selectedImage;
  bool isSubmitting = false;

  final List<String> sexes = ['Masculin', 'Féminin', 'Autre'];
  final List<String> etatsCivils = ['Célibataire', 'Marié(e)', 'Divorcé(e)', 'Veuf(ve)'];

  @override
  void initState() {
    super.initState();
    final data = widget.userData;

    nomController = TextEditingController(text: data['nom'] ?? '');
    prenomController = TextEditingController(text: data['prenom'] ?? '');
    emailController = TextEditingController(text: data['email'] ?? '');
    telephoneController = TextEditingController(text: data['telephone'] ?? '');
    professionController = TextEditingController(text: data['profession'] ?? '');
    villeController = TextEditingController(text: data['villeResidence'] ?? '');
    nationaliteController = TextEditingController(text: data['nationalite'] ?? '');
    lieuNaissanceController = TextEditingController(text: data['lieuNaissance'] ?? '');
    photoController = TextEditingController(text: data['photo'] ?? '');

    selectedSexe = data['sexe'] != null && sexes.contains(data['sexe']) ? data['sexe'] : null;
    selectedEtatCivil = data['etatCivil'] != null && etatsCivils.contains(data['etatCivil']) ? data['etatCivil'] : null;

    if (data['dateNaissance'] != null && data['dateNaissance'] != '') {
      dateNaissance = DateTime.tryParse(data['dateNaissance']);
    }
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    professionController.dispose();
    villeController.dispose();
    nationaliteController.dispose();
    lieuNaissanceController.dispose();
    photoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: dateNaissance ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        dateNaissance = pickedDate;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final Map<String, dynamic> updateData = {};

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        updateData[key] = value.trim();
      }
    }

    addIfNotEmpty("nom", nomController.text);
    addIfNotEmpty("prenom", prenomController.text);
    addIfNotEmpty("email", emailController.text);
    addIfNotEmpty("telephone", telephoneController.text);
    addIfNotEmpty("profession", professionController.text);
    addIfNotEmpty("villeResidence", villeController.text);
    addIfNotEmpty("nationalite", nationaliteController.text);
    addIfNotEmpty("lieuNaissance", lieuNaissanceController.text);

    if (selectedEtatCivil != null) {
      updateData["etatCivil"] = selectedEtatCivil!;
    }
    if (selectedSexe != null) {
      updateData["sexe"] = selectedSexe!;
    }

    if (widget.userData['role'] != null) {
      updateData["role"] = widget.userData['role'];
    }

    if (dateNaissance != null) {
      updateData["dateNaissance"] =
          "${dateNaissance!.year.toString().padLeft(4, '0')}-"
          "${dateNaissance!.month.toString().padLeft(2, '0')}-"
          "${dateNaissance!.day.toString().padLeft(2, '0')}";
    }

    try {
      if (selectedImage != null) {
        updateData.remove("photo");
        await AuthService.updateCurrentUserWithImage(
          widget.userData['utilisateur_id'],
          updateData,
          selectedImage!,
        );
      } else {
        addIfNotEmpty("photo", photoController.text);
        await AuthService.updateCurrentUser(
          widget.userData['utilisateur_id'],
          updateData,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès.")),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier Profil", style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6, bottom: 12),
                              child: TextFormField(
                                controller: nomController,
                                decoration: inputDecoration("Nom"),
                                style: const TextStyle(fontSize: 13),
                                validator: (v) => (v == null || v.isEmpty) ? "Ce champ est requis" : null,
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, bottom: 12),
                              child: TextFormField(
                                controller: prenomController,
                                decoration: inputDecoration("Prénom"),
                                style: const TextStyle(fontSize: 13),
                                validator: (v) => (v == null || v.isEmpty) ? "Ce champ est requis" : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      TextFormField(
                        controller: emailController,
                        decoration: inputDecoration("Email"),
                        style: const TextStyle(fontSize: 13),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Ce champ est requis";
                          final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                          if (!regex.hasMatch(v)) return "Email invalide";
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: telephoneController,
                        decoration: inputDecoration("Téléphone"),
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: professionController,
                        decoration: inputDecoration("Profession"),
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: villeController,
                        decoration: inputDecoration("Ville de résidence"),
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: nationaliteController,
                        decoration: inputDecoration("Nationalité"),
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: lieuNaissanceController,
                        decoration: inputDecoration("Lieu de naissance"),
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Flexible(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6, bottom: 12),
                              child: DropdownButtonFormField<String>(
                                value: selectedEtatCivil,
                                decoration: inputDecoration("État civil"),
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                items: etatsCivils
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedEtatCivil = val;
                                  });
                                },
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, bottom: 12),
                              child: DropdownButtonFormField<String>(
                                value: selectedSexe,
                                decoration: inputDecoration("Sexe"),
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                items: sexes
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedSexe = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Date de naissance", style: TextStyle(fontSize: 13)),
                        subtitle: Text(
                          dateNaissance != null
                              ? "${dateNaissance!.day.toString().padLeft(2, '0')}/"
                                  "${dateNaissance!.month.toString().padLeft(2, '0')}/"
                                  "${dateNaissance!.year}"
                              : "Non définie",
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (selectedImage != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Aperçu de la nouvelle photo :",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage!,
                                    height: 130,
                                    width: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.redAccent,
                                    radius: 13,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 17,
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          selectedImage = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),

                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text("Changer la photo"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ).copyWith(
                          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 13)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: AppColors.primary.withOpacity(0.5),
                        ).copyWith(
                          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        child: const Center(
                          child: Text(
                            "Enregistrer",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
