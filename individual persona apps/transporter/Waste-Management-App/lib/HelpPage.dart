import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help page',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Card(child: new Text("1. Press green button to login")),
            Card(child: new Text("2. Connect to bin")),
            Card(child: new Text("3. Choose lock or unlock by pressing change button")),
            Card(child: new Text("4. Press green button to lock/unlock")),
          ],
        ),
      ),
    );
  }
}
