import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/utilisateur_model.dart';
import '../services/utilisateur_service.dart';
import 'dart:io';
import '../constants/roles.dart';

class CreateUtilisateurScreen extends StatefulWidget {
  const CreateUtilisateurScreen({super.key});

  @override
  State<CreateUtilisateurScreen> createState() => _CreateUtilisateurScreenState();
}

class _CreateUtilisateurScreenState extends State<CreateUtilisateurScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _professionController;
  late TextEditingController _villeResidenceController;
  late TextEditingController _nationaliteController;
  late TextEditingController _lieuNaissanceController;
  late TextEditingController _etatCivilController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  RoleEnum _selectedRole = RoleEnum.Fidele;
  String? _selectedSexe;
  DateTime? _selectedDateNaissance;
  XFile? _selectedPhoto;

  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _telephoneController = TextEditingController();
    _professionController = TextEditingController();
    _villeResidenceController = TextEditingController();
    _nationaliteController = TextEditingController();
    _lieuNaissanceController = TextEditingController();
    _etatCivilController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _professionController.dispose();
    _villeResidenceController.dispose();
    _nationaliteController.dispose();
    _lieuNaissanceController.dispose();
    _etatCivilController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _selectedPhoto = picked);
    }
  }

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur créé avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    // 🔍 Vérification si l’email existe déjà
    final email = _emailController.text.trim();
    final emailExists = await UtilisateurService.checkEmailExists(email);

    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cet email est déjà utilisé')),
      );
      return;
    }

    final utilisateurData = Utilisateur(
      utilisateurId: 0,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: email,
      role: _selectedRole,
      photo: _selectedPhoto?.path,
      telephone: _telephoneController.text.trim(),
      profession: _professionController.text.trim(),
      villeResidence: _villeResidenceController.text.trim(),
      nationalite: _nationaliteController.text.trim(),
      lieuNaissance: _lieuNaissanceController.text.trim(),
      etatCivil: _etatCivilController.text.trim(),
      sexe: _selectedSexe,
      dateNaissance: _selectedDateNaissance,
      password: _passwordController.text,
    );

    await _performAction(() => UtilisateurService.createUtilisateur(utilisateurData));
  }

  Widget _buildDatePicker() {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Date de naissance'),
      child: ListTile(
        title: Text(_selectedDateNaissance == null
            ? 'Sélectionner une date'
            : DateFormat('dd/MM/yyyy').format(_selectedDateNaissance!)),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDateNaissance ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null && mounted) {
            setState(() => _selectedDateNaissance = picked);
          }
        },
      ),
    );
  }

  Widget _buildSexeDropdown() {
    const options = ['Masculin', 'Féminin', 'Autre'];
    return DropdownButtonFormField<String>(
      value: _selectedSexe,
      decoration: const InputDecoration(labelText: 'Sexe'),
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (value) {
        if (value != null && mounted) setState(() => _selectedSexe = value);
      },
    );
  }

  Widget _buildPhotoSection() {
    final photoWidget = _selectedPhoto != null
        ? Image.file(File(_selectedPhoto!.path), width: 100, height: 100, fit: BoxFit.cover)
        : const Icon(Icons.account_circle, size: 100, color: Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPhoto,
          child: ClipOval(child: photoWidget),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowedRoles = UtilisateurRoles.allowed.map((roleName) {
      return RoleEnum.values.firstWhere(
        (r) => r.toString().split('.').last.toLowerCase() == roleName.toLowerCase(),
        orElse: () => RoleEnum.Fidele,
      );
    }).toSet().toList();

    if (!allowedRoles.contains(_selectedRole)) {
      _selectedRole = allowedRoles.isNotEmpty ? allowedRoles.first : RoleEnum.Fidele;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Créer Utilisateur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildPhotoSection(),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom"),
                validator: (value) => value == null || value.trim().isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: "Prénom"),
                validator: (value) => value == null || value.trim().isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Champ requis';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) return 'Email invalide';
                  return null;
                },
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: "Téléphone"),
              ),
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(labelText: "Profession"),
              ),
              TextFormField(
                controller: _villeResidenceController,
                decoration: const InputDecoration(labelText: "Ville de résidence"),
              ),
              TextFormField(
                controller: _nationaliteController,
                decoration: const InputDecoration(labelText: "Nationalité"),
              ),
              TextFormField(
                controller: _lieuNaissanceController,
                decoration: const InputDecoration(labelText: "Lieu de naissance"),
              ),
              TextFormField(
                controller: _etatCivilController,
                decoration: const InputDecoration(labelText: "État civil"),
              ),
              _buildSexeDropdown(),
              _buildDatePicker(),
              DropdownButtonFormField<RoleEnum>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: "Rôle"),
                items: allowedRoles.map((role) {
                  final displayText = role.toString().split('.').last;
                  return DropdownMenuItem(value: role, child: Text(displayText));
                }).toList(),
                onChanged: (value) {
                  if (value != null && mounted) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Mot de passe"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (value.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: "Confirmer mot de passe"),
                obscureText: true,
                validator: (value) {
                  if (_passwordController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'Champ requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Créer'),
                  onPressed: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
