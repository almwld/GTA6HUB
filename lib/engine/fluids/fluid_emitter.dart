import 'dart:math';
import 'package:flutter/material.dart';
import 'fluid_particle.dart';

class FluidEmitter {
  final Random _random = Random();

  List<FluidParticle> emitCum(Offset origin, Offset direction, double power) {
    List<FluidParticle> batch = [];
    int count = (50.0 * power).toInt();
    for (int i = 0; i < count; i++) {
      double angle = atan2(direction.dy, direction.dx) + (_random.nextDouble() - 0.5) * 0.8;
      double speed = (200.0 + _random.nextDouble() * 400.0) * power;
      batch.add(FluidParticle(position: origin + Offset(_random.nextDouble() * 4, _random.nextDouble() * 4), velocity: Offset(cos(angle) * speed, sin(angle) * speed), life: 0.8 + _random.nextDouble() * 0.4, radius: 2.0 + _random.nextDouble() * 4.0, viscosity: 8.0, color: const Color(0xFFF0F0F5)));
    }
    return batch;
  }

  List<FluidParticle> emitSquirt(Offset origin, Offset direction, double power) {
    List<FluidParticle> batch = [];
    int count = (80.0 * power).toInt();
    for (int i = 0; i < count; i++) {
      double angle = atan2(direction.dy, direction.dx) + (_random.nextDouble() - 0.5) * 1.5;
      double speed = (100.0 + _random.nextDouble() * 500.0) * power;
      batch.add(FluidParticle(position: origin, velocity: Offset(cos(angle) * speed, sin(angle) * speed), life: 0.5 + _random.nextDouble() * 0.5, radius: 1.0 + _random.nextDouble() * 2.5, viscosity: 1.0, color: const Color(0x88E0F7FA)));
    }
    return batch;
  }
}
