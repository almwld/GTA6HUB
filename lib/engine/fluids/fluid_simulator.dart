import 'dart:ui';
import 'package:flutter/material.dart';
import 'fluid_particle.dart';

class FluidSimulator {
  final List<FluidParticle> _particles = [];
  List<FluidParticle> get particles => _particles;

  void update(double delta) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life -= delta * 0.3;
      if (p.life <= 0) { _particles.removeAt(i); continue; }
      p.velocity += const Offset(0, 200.0) * delta;
      p.velocity *= (1.0 - (p.viscosity * delta));
      p.position += p.velocity * delta;
      p.radius *= (0.95 + (p.life * 0.05));
    }
  }

  void emitParticles(List<FluidParticle> newParticles) { _particles.addAll(newParticles); }
  void clear() { _particles.clear(); }

  void render(Canvas canvas) {
    for (final p in _particles) {
      final paint = Paint()..color = p.color.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.drawCircle(p.position, p.radius, paint);
      final highlight = Paint()..color = Colors.white.withOpacity(p.life * 0.6);
      canvas.drawCircle(p.position - Offset(p.radius * 0.3, p.radius * 0.3), p.radius * 0.3, highlight);
    }
  }
}
