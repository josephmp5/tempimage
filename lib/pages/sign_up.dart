import 'package:fleetingframes/auth/auth.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  void signIn() async {
    await Auth().signInAnonymously(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00BFFF),
              Color(0xFF1E90FF),
              Color(0xFF00008B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Welcome to fleeting frames if you dont want to keep an image in your phone and deleted later your in the right place.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize:
                          MediaQuery.of(context).size.width > 600 ? 24.0 : 20.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "When more than 1 images uploaded screen can be scrollable horizontally and if you want to look at images you can zoom in and out.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize:
                          MediaQuery.of(context).size.width > 600 ? 24.0 : 20.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 100,
              ),
              SizedBox(
                height: 50,
                width: 200,
                child: ElevatedButton(
                    onPressed: signIn,
                    child: const Text(
                      'Click to Sign In',
                      style: TextStyle(color: Colors.blue, fontSize: 20),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
