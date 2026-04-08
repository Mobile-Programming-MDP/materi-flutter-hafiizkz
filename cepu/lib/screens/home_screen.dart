import 'package:cepu/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false,
    );
  }

  Future<String?> getTokenAuth() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? idToken = await user.getIdToken(true);
      return idToken;
    }

    return null;
  }

  String? _idToken = "";
  String? _uid = "";
  String? _email = "";

  Future<void> getFirebaseAuthUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _uid = user.uid;
      _email = user.email;
      await user
          .getIdToken(true)
          .then(
            (value) => {
              setState(() {
                _idToken = value;
              }),
            },
          );
    }
  }

  String generateAvatarUrl(String? fullname) {
    final formattedName = fullname!.trim().replaceAll(' ', '+');
    return 'https://ui-avatars.com/api/?name=$formattedName&color=7F9CF5&background=EBF4FF';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.logout))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              generateAvatarUrl(
                FirebaseAuth.instance.currentUser?.displayName.toString(),
              ),
              width: 100,
              height: 100,
            ),
            Text("hellow"),
            Text("UID: $_uid"),
            Text("Email: $_email"),
            Text("Token: $_idToken"),
          ],
        ),
      ),
    );
  }
}
