import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAuthProvider with ChangeNotifier {
  String _userId = "";
  bool _authenticated = false;
  String _role = "";
  String _userName = "Anonymous";
  String _email = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isAuthenticated {
    return _authenticated;
  }

  String get userId {
    return _userId;
  }
  
  String get userName {
    return _userName;
  }

  String get email {
    return _email;
  }

  String get role {
    return _role;
  }

  MyAuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        _authenticated = true;
        _loadUserDetails(user.uid);
      } else {
        _userId = "";
        _authenticated = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserDetails(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = 
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      _role = snapshot.data()?['role'] ?? "";
      _userName = snapshot.data()?['username'] ?? "Anonymous";
      _email = snapshot.data()?['email'] ?? "";
    }

    notifyListeners();
  }

  Future<String> signup({
    required String email,
    required String password,
    required String username,
    required String role
  }) async {
    try {
      UserCredential authResult = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authResult.user!.uid)
          .set({
            'username': username,
            'email': email,
            'role': role,
          });

      return "success";
    } catch (err) {
      print("The error is: " + err.toString());
      throw err;
    }
  }

  Future<String> signin({
    required String email,
    required String password
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserDetails(_auth.currentUser!.uid);
      return "success";
    } catch (err) {
      print("The error is: " + err.toString());
      throw err;
    }
  }

  void updateUsername(String newUsername) {
    _userName = newUsername;
    notifyListeners();
  }

  void logout() {
    _userId = "";
   _authenticated = false;
   _role = "";
   _userName = "Anonymous";
   _email = "";
    _auth.signOut();
    _authenticated = false;
    notifyListeners();
  }
}
