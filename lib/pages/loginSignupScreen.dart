import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/providers/authProvider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var usernameController = TextEditingController();
  var role = 'Shopper'; // Default role is Shopper

  final authenticationInstance = FirebaseAuth.instance;

  var authenticationMode = 0;

  void toggleAuthMode() {
    setState(() {
      authenticationMode = authenticationMode == 0 ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: 400,
        margin: EdgeInsets.only(top: 100, left: 10, right: 10),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Center(
                  child: Text(
                    "E-Commerce App",
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Email"),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Password"),
                  controller: passwordController,
                  obscureText: true,
                ),
                if (authenticationMode == 1)
                  TextField(
                    decoration: InputDecoration(labelText: "Username"),
                    controller: usernameController,
                  ),
                if (authenticationMode == 1) // Display role selection only during sign-up
                  DropdownButtonFormField(
                    decoration: InputDecoration(labelText: "Role"),
                    value: role,
                    items: ['Shopper', 'Vendor']
                        .map((role) => DropdownMenuItem(
                              child: Text(role),
                              value: role,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        role = value.toString();
                      });
                    },
                  ),
                ElevatedButton(
                  onPressed: loginOrSignup,
                  child: (authenticationMode == 1) ? Text("Sign up") : Text("Login"),
                ),
                TextButton(
                  onPressed: toggleAuthMode,
                  child: (authenticationMode == 1) ? Text("Login instead") : Text("Sign up instead"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void loginOrSignup() async {
    var email = emailController.text.trim();
    var password = passwordController.text.trim();
    var username = usernameController.text.trim();

    var authprov = Provider.of<MyAuthProvider>(context, listen: false);

    try {
      if (authenticationMode == 1) { // Sign up
        var successOrError = await authprov.signup(email: email, password: password, username: username, role: role);
        if (successOrError == "success") {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/');
          }
        } else {
          if (mounted) {
            showErrorDialog(successOrError);
          }
        }
      } else { // Log in
        var successOrError = await authprov.signin(email: email, password: password);
        if (successOrError == "success") {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/');
          }
        } else {
          if (mounted) {
            showErrorDialog(successOrError);
          }
        }
      }
    } catch (err) {
      print(err.toString());
      if (mounted) {
        showErrorDialog(err.toString());
      }
    }
  }

  void showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('An Error Occurred!'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            )
          ],
        ),
      );
    }
  }
}
