import 'dart:ui';

class FluidParticle {
  Offset position;
  Offset velocity;
  double life;
  double radius;
  double viscosity;
  Color color;

  FluidParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.radius,
    required this.viscosity,
    required this.color,
  });
}
