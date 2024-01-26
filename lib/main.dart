import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fleetingframes/firebase_options.dart';
import 'package:fleetingframes/pages/home_page.dart';
import 'package:fleetingframes/pages/sign_up.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Fleeting Frames',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // Check if the user is signed in
            if (snapshot.hasData && snapshot.data != null) {
              // Ensure the user is not null
              String userId = snapshot.data!.uid;
              return HomePage(
                  userId: userId); // Navigate to the HomePage if signed in
            }
            return const SignUp(); // Otherwise, show the SignUp page
          }
          return const Scaffold(
              body: Center(
                  child:
                      CircularProgressIndicator())); // Show loading screen while waiting
        },
      ),
    );
  }
}
