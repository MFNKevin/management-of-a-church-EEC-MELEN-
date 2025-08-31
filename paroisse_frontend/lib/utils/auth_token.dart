import 'package:shared_preferences/shared_preferences.dart';

class AuthToken {
  static const String _keyToken = 'auth_token';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyUserNomComplet = 'user_nomComplet';  // Ajout clé nom complet

  // ===== TOKEN =====
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  // ===== RÔLE UTILISATEUR =====
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
  }

  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserRole);
  }

  // ===== ID UTILISATEUR =====
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  static Future<void> setUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  // ===== NOM COMPLET UTILISATEUR =====
  static Future<String?> getUserNomComplet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserNomComplet);
  }

  static Future<void> setUserNomComplet(String nomComplet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserNomComplet, nomComplet);
  }

  static Future<void> clearUserNomComplet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserNomComplet);
  }

  // ===== SYNCHRONISATION =====
  static Future<void> ensureUserData() async {
    await getToken();
    await getUserRole();
    await getUserId();
    await getUserNomComplet();
  }

  // ===== DECONNEXION =====
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserNomComplet);
  }
}
