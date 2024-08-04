// pages/ar.dart
import 'package:flutter/material.dart';
import 'package:flutterapp/mobiletourism.dart';

class ARPage extends StatelessWidget {
  const ARPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('AR Page'),
      ),
      body: MobileTourismWidget(uid: 'o7hYM5Rw6fO71Jhm81Lt8sIkeiC3',)
    );
  }
}
