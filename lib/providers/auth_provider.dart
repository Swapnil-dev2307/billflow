import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await fetchUserProfile();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> fetchUserProfile() async {
    if (_user != null) {
      _userModel = await _authRepository.getUserProfile(_user!.uid);
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _userModel = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        phone: phone,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      await fetchUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _userModel = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
