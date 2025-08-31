import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:paroisse_frontend/utils/auth_token.dart';
import 'package:paroisse_frontend/config.dart';

class AuthService {
  static const String apiRoute = '/api';
  static String get fullUrl => '${Config.baseUrl}$apiRoute';

  /// Helper pour créer headers avec token
  static Future<Map<String, String>> _authHeaders({Map<String, String>? extraHeaders}) async {
    final token = await AuthToken.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token vide, veuillez vous connecter.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };
  }

  /// 🔐 Connexion : envoie email et mot de passe pour récupérer un token JWT
  /// Le stockage du rôle/id/nomComplet est fait uniquement après getCurrentUser()
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$fullUrl/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['access_token'] != null) {
        await AuthToken.setToken(data['access_token']);
      }

      // Ne pas stocker user ici, car pas forcément présent dans la réponse
    }

    return response;
  }

  /// 👤 Récupérer les infos utilisateur connecté
  /// Ici, on stocke le rôle, l'id, et nomComplet après la récupération
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final url = Uri.parse('$fullUrl/utilisateurs/me');

    final headers = await _authHeaders();

    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      // Stockage rôle/id/nomComplet dans AuthToken
      if (userData['role'] != null) {
        await AuthToken.setUserRole(userData['role']);
      }
      if (userData['utilisateur_id'] != null) {
        await AuthToken.setUserId(userData['utilisateur_id']);
      }
      if (userData['nomComplet'] != null) {
        await AuthToken.setUserNomComplet(userData['nomComplet']);
      }

      return userData;
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée ou non autorisée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Impossible de récupérer les infos utilisateur : '
          'Erreur ${response.statusCode} - ${response.body}');
    }
  }

  /// ✏️ Mise à jour des infos utilisateur (sans image)
  static Future<void> updateCurrentUser(
    int utilisateurId,
    Map<String, dynamic> updateData,
  ) async {
    final url = Uri.parse('$fullUrl/utilisateurs/update/$utilisateurId');

    final headers = await _authHeaders(extraHeaders: {'Content-Type': 'application/json'});

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 401) {
      throw Exception('Session expirée ou non autorisée. Veuillez vous reconnecter.');
    } else if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour du profil : ${response.body}');
    }
  }

  /// 🖼 Mise à jour des infos utilisateur avec image (multipart/form-data)
  static Future<void> updateCurrentUserWithImage(
    int utilisateurId,
    Map<String, dynamic> updateData,
    File? imageFile,
  ) async {
    final uri = Uri.parse('$fullUrl/utilisateurs/update/$utilisateurId');

    final token = await AuthToken.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token vide, veuillez vous connecter.');
    }

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    // Champs texte
    updateData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Image si présente
    if (imageFile != null) {
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'photo',
        stream,
        length,
        filename: basename(imageFile.path),
      );
      request.files.add(multipartFile);
    }

    final response = await request.send();

    if (response.statusCode == 401) {
      throw Exception('Session expirée ou non autorisée. Veuillez vous reconnecter.');
    } else if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Erreur lors de la mise à jour avec image : $respStr');
    }
  }
}
