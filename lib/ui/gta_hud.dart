import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/simulation_provider.dart';

class GTAHud extends StatelessWidget {
  const GTAHud({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationProvider>(
      builder: (context, sim, child) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(top: 20, left: 20, child: _bar('AROUSAL', sim.arousal, const Color(0xFFFF2A6D))),
              Positioned(top: 20, right: 20, child: _bar('STAMINA', sim.stamina, const Color(0xFF00E5FF))),
              Positioned(top: 20, left: 0, right: 0, child: Center(child: Text(sim.currentPosition.toUpperCase(), style: const TextStyle(color: Colors.white54, letterSpacing: 4)))),
              Positioned(bottom: 20, left: 20, right: 20, child: _controls(sim)),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(String label, double value, Color color) {
    return Container(
      width: 100, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: value/100, backgroundColor: color.withOpacity(0.3), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6),
          Text('${value.toInt()}%', style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _controls(SimulationProvider sim) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btn(Icons.arrow_upward, () => sim.increaseSpeed(), 'SPD'),
        _btn(Icons.arrow_downward, () => sim.decreaseSpeed(), 'SPD'),
        _btn(Icons.arrow_upward, () => sim.increaseDepth(), 'DEP'),
        _btn(Icons.arrow_downward, () => sim.decreaseDepth(), 'DEP'),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [Icon(icon, color: Colors.white70, size: 24), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))]),
    );
  }
}
