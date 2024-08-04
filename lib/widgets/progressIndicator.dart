// widgets/progressIndicator.dart
import 'package:flutter/material.dart';

class CircularPercentageIndicator extends StatelessWidget {
  final double progress;

  const CircularPercentageIndicator({required this.progress, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: progress,
          strokeWidth: 6.0,
        ),
        Padding(
          padding: const EdgeInsets.only(
              top: 10.0, bottom: 10.0, right: 10.0, left: 10.0),
          child: Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
