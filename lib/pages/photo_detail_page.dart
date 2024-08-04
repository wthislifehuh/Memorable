import 'package:flutter/material.dart';

class PhotoDetailPage extends StatelessWidget {
  final String imagePath;

  const PhotoDetailPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Detail'),
      ),
      body: Center(
        child: Image.asset(imagePath),
      ),
    );
  }
}
