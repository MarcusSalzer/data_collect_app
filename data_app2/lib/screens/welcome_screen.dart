import 'package:data_app2/screens/home_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome!")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text("hello"), Text("Thanks for checking out the app.")],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
                    },
                    label: Text("Get started"),
                    icon: Icon(Icons.home),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
