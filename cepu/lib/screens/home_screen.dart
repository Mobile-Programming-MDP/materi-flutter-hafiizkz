import 'package:cepu/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> signOut(BuildContext context)async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(context,
    MaterialPageRoute(builder: (context) => SignInScreen()),
    (route) => false 
    );
  }

  String? _idToken = "";
  String? _uid = "";
  String? _email = "";
  Future<void> getFirebaseAuthUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      _uid = user.uid;
      _email = user.email;
      await user.getIdToken(true).then((v) => {setState(() {
        _idToken = v;
      }),
      },
      );
    }
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: (){
              signOut(context);
            },icon: const Icon(Icons.logout),
          ),
        ],
        ),
      body: Center(
        child : Column(
          children: [
            Text("You Have Been Signed In with Token Id : ${_idToken!}"),
            Text("Current User : ${_uid!}"),
            Text("Current Email : ${_email!}"),
          ],
        ),
      ),
    );
  }
}
