import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffProvider with ChangeNotifier {
  String? _id;
  String? _staffId;
  String? _fullName;
  String? _email;
  String? _phone;
  String? _role;
  String? _companyId;
  String? _token;
  String? _companyName;

  bool _isCheckingAuth = true; // start true until we check storage

  // Getters
  String? get id => _id;
  String? get staffId => _staffId;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get phone => _phone;
  String? get role => _role;
  String? get companyId => _companyId;
  String? get token => _token;
  String? get companyName => _companyName;

  bool get isCheckingAuth => _isCheckingAuth;
  bool get isLoggedIn => _token != null;

  StaffProvider() {
    _loadStaffFromPrefs();
  }

  Future<void> _loadStaffFromPrefs() async {
    _isCheckingAuth = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    _id = prefs.getString("id");
    _staffId = prefs.getString("staffId");
    _fullName = prefs.getString("fullName");
    _email = prefs.getString("email");
    _phone = prefs.getString("phone");
    _role = prefs.getString("role");
    _companyId = prefs.getString("companyId");
    _companyName = prefs.getString("companyName");

    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<void> setStaff({
    required String id,
    required String staffId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String? companyId,
    required String token,
    required String companyName,
  }) async {
    _id = id;
    _staffId = staffId;
    _fullName = fullName;
    _email = email;
    _phone = phone;
    _role = role;
    _companyId = companyId;
    _token = token;
    _companyName = companyName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("id", id);
    await prefs.setString("staffId", staffId);
    await prefs.setString("fullName", fullName);
    await prefs.setString("email", email);
    await prefs.setString("phone", phone);
    await prefs.setString("role", role);
    if (companyId != null) await prefs.setString("companyId", companyId);
    await prefs.setString("token", token);
    await prefs.setString("companyName", companyName);

    notifyListeners();
  }

  Future<void> logout() async {
    _id = null;
    _staffId = null;
    _fullName = null;
    _email = null;
    _phone = null;
    _role = null;
    _companyId = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
