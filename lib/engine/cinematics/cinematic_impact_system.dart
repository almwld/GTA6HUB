import 'package:flutter/material.dart';
import 'dart:math';

class CinematicImpactSystem extends StatefulWidget {
  final Widget child;
  final double arousal;
  final String currentState;
  const CinematicImpactSystem({Key? key, required this.child, required this.arousal, required this.currentState}) : super(key: key);
  @override
  State<CinematicImpactSystem> createState() => _CinematicImpactSystemState();
}

class _CinematicImpactSystemState extends State<CinematicImpactSystem> with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _shakeController;
  late AnimationController _vignetteController;
  double _shakeX = 0.0, _shakeY = 0.0;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _shakeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _vignetteController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _shakeController.addListener(() { if (_shakeController.isAnimating) { final i = _shakeController.value; _shakeX = (Random().nextDouble() - 0.5) * 30 * i; _shakeY = (Random().nextDouble() - 0.5) * 30 * i; setState(() {}); } });
    _shakeController.addStatusListener((s) { if (s == AnimationStatus.completed) { _shakeX = 0.0; _shakeY = 0.0; setState(() {}); } });
  }

  @override
  void didUpdateWidget(covariant CinematicImpactSystem old) {
    super.didUpdateWidget(old);
    if (widget.currentState == "peak" && widget.arousal >= 95.0) { _trigger(); }
    else if (widget.currentState == "idle" || widget.currentState == "exhausted") { _reset(); }
    _vignetteController.animateTo(widget.arousal / 100.0);
  }

  void _trigger() { _flashController.reset(); _flashController.forward(); _shakeController.reset(); _shakeController.forward(); }
  void _reset() { _flashController.reverse(); _shakeController.stop(); _shakeX = 0.0; _shakeY = 0.0; _vignetteController.animateTo(0.0); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: Listenable.merge([_flashController, _shakeController, _vignetteController]), builder: (ctx, child) {
      return Transform.translate(offset: Offset(_shakeX, _shakeY), child: Stack(children: [
        widget.child,
        IgnorePointer(child: Container(color: Colors.white.withOpacity(_flashController.value * 0.4))),
        IgnorePointer(child: CustomPaint(painter: _VignettePainter(intensity: _vignetteController.value), size: Size.infinite)),
      ]));
    });
  }

  @override
  void dispose() { _flashController.dispose(); _shakeController.dispose(); _vignetteController.dispose(); super.dispose(); }
}

class _VignettePainter extends CustomPainter {
  final double intensity;
  _VignettePainter({required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height/2);
    final r = size.shortestSide * 0.7;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = ui.Gradient.radial(c, r * (1.0 - intensity * 0.5), [Colors.transparent, Colors.black.withOpacity(intensity * 0.8)]));
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder({Key? key, required Listenable animation, required this.builder}) : super(key: key, listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, null);
}
