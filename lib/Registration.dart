import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './custom widgets/customtextfild.dart';
import './login.dart';
import './HomePage.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _sighupFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  String selectedGender = "female";

  void onPressed() async {
    if (_sighupFormKey.currentState!.validate()) {
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        await FirebaseFirestore.instance
            .collection("users")
            .doc(credential.user!.uid)
            .set({
              "name": _nameController.text.trim(),
              "email": _emailController.text.trim(),
              "phone": _phoneController.text.trim(),
              "job": _jobController.text.trim(),
              "address": _addressController.text.trim(),
              "gender": selectedGender,
              "uid": credential.user!.uid,
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User registered successfully")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } on FirebaseAuthException catch (e) {
        print("Firebase Error: ${e.code}"); 
        String message = "Something went wrong!";
        if (e.code == 'email-already-in-use') {
          message = "This email is already registered.";
        } else if (e.code == 'weak-password') {
          message = "The password is too weak.";
        } else if (e.code == 'invalid-email') {
          message = "Invalid email format.";
        } else if (e.code == 'operation-not-allowed') {
          message = "Email/password accounts are not enabled in Firebase.";
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sighup",
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
            key: _sighupFormKey,
            child: ListView(
              children: [
                SizedBox(height: 30),
                CustomTextField(
                  controller: _nameController,
                  labelText: "Name",
                  hintText: "enter your name",
                  inputType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "plz enter you name";
                    }
                    if (value.length < 3) {
                      return "plz enter valid name ";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
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
                CustomTextField(
                  controller: _jobController,
                  labelText: "Job",
                  hintText: "enter your Job",
                  inputType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "plz enter you job";
                    }
                    if (value.length < 5) {
                      return "plz enter valid job ";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                CustomTextField(
                  controller: _phoneController,
                  labelText: "Phone number",
                  hintText: "enter your Phone number",
                  inputType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "plz enter you Phone number";
                    }
                    if (value.length < 3) {
                      return "plz enter valid Phone number ";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                CustomTextField(
                  controller: _addressController,
                  labelText: "Address",
                  hintText: "enter your Address",
                  inputType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "plz enter you Address";
                    }
                    if (value.length < 5) {
                      return "plz enter valid Address ";
                    }
                    return null;
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    const Text(
                      "Gender:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: "Female",
                          groupValue: selectedGender,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 61, 83, 209),
                        ),
                        const Text("Female"),
                        SizedBox(width: 30),
                        Radio<String>(
                          value: "male",
                          groupValue: selectedGender,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 61, 83, 209),
                        ),
                        const Text("Male"),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 61, 83, 209),
                    padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    "Sighup",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Login",
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
