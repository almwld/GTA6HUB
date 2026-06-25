import 'package:flutter/material.dart';

class CinematicImpactSystem extends StatelessWidget {
  final Widget child;
  final double arousal;
  final String currentState;

  const CinematicImpactSystem({
    Key? key,
    required this.child,
    required this.arousal,
    required this.currentState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double intensity = (arousal / 100.0).clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color: currentState == "peak" 
              ? const Color(0xFFFF2A6D).withOpacity(intensity)
              : Colors.transparent,
          width: 5.0 * intensity,
        ),
      ),
      child: child,
    );
  }
}
