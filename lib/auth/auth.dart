import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleetingframes/main.dart';
import 'package:fleetingframes/pages/home_page.dart';
import 'package:fleetingframes/show_snackbar.dart';
import 'package:flutter/material.dart';

class Auth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInAnonymously({required BuildContext context}) async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          'uid': user.uid,
        });

        // Use `user.uid` directly here instead of `FirebaseAuth.instance.currentUser?.uid`
        await MyApp.navigatorKey.currentState
            ?.pushReplacement(MaterialPageRoute(
          builder: (context) => HomePage(userId: user.uid),
        ));
      } else {
        // Handle the case where the user object is null
        showSnackBar(context, "Sign in failed: User is null");
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
  }
}
