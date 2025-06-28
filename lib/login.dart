import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import './Registration.dart';
import './custom widgets/customtextfild.dart';
import './HomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _loginSubmit() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } on FirebaseAuthException catch (e) {
        String message = "Something went wrong.";
        if (e.code == 'user-not-found') {
          message = "User not found.";
        } else if (e.code == 'wrong-password') {
          message = "Wrong password.";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void signInWithFacebook() async {
     print("User info1:");
    try {
      final LoginResult result = await FacebookAuth.instance.login();
       print("User info2:");

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.token,
        );
         print("User info3:");

        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
         print("User info4:");

        final user = userCredential.user;
        if (user != null) {
          final userDoc = FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid);
          final docSnapshot = await userDoc.get();
           print("User info5:");

          if (!docSnapshot.exists) {
            await userDoc.set({
              "name": user.displayName ?? "",
              "email": user.email ?? "",
              "uid": user.uid,
              "job": "",
              "address": "",
            });
          }
           print("User info6:");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Homepage()),
          );
        }
      } else {
        print(" Facebook login failed: ${result.message}");
      }
    } catch (e) {
      print("Error during Facebook sign in: $e");
    }
  }

  void signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.standard();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      print("User info1:");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print("User info2:");

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      print("User info3:");

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      print("User info: ${user?.email}");

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            "name": user.displayName ?? "",
            "email": user.email ?? "",
            "uid": user.uid,
            "job": "",
            "address": "",
          });
        }
        print(" Reached here before navigation");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      }
    } catch (e) {
      print(" Error during Google sign in: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Login",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 83, 209),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Form(
            key: _loginFormKey,

            child: ListView(
              children: [
                SizedBox(height: 150),
                CustomTextField(
                  controller: _emailController,
                  labelText: "Email",
                  hintText: "enter your email",
                  inputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "plz enter you email";
                    }
                    if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(value)) {
                      return "plz enter  valid Email ";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                CustomTextField(
                  controller: _passwordController,
                  labelText: "Password",
                  obscureText: true,
                  hintText: "enter your passord",
                  inputType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "plz enter you password";
                    }
                    if (value.length < 6) {
                      return "plz enter valid password ";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _loginSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 61, 83, 209),
                    padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    print("👉 Google button pressed");
                    signInWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        "images/icons8-google.svg",
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Continue with Google",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: signInWithFacebook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        "images/icons8-facebook.svg",
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Sighin with Facebook",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Registration()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Register",
                    style: TextStyle(
                      color: Color.fromARGB(255, 71, 72, 164),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
