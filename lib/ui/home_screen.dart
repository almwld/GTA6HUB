import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/simulation_provider.dart';
import '../engine/fluids/fluid_simulator.dart';
import '../engine/fluids/fluid_emitter.dart';
import '../engine/cinematics/cinematic_impact_system.dart';
import 'gta_hud.dart';
import 'director_sandbox.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final FluidSimulator _fluidSimulator = FluidSimulator();
  final FluidEmitter _fluidEmitter = FluidEmitter();
  SimulationState _lastState = SimulationState.idle;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final simProvider = Provider.of<SimulationProvider>(context, listen: false);
      double delta = elapsed.inMilliseconds / 1000.0;
      simProvider.update(delta);
      _fluidSimulator.update(delta);
      if (simProvider.currentState == SimulationState.peak && _lastState != SimulationState.peak) {
        final origin = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2);
        final direction = const Offset(0, -1);
        final newParticles = _fluidEmitter.emitCum(origin, direction, (simProvider.thrustSpeed / 50.0).clamp(0.5, 2.0));
        _fluidSimulator.emitParticles(newParticles);
      }
      _lastState = simProvider.currentState;
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sim = Provider.of<SimulationProvider>(context);
    return Scaffold(
      body: CinematicImpactSystem(
        arousal: sim.arousal,
        currentState: sim.currentState.name,
        child: Stack(
          children: [
            Container(color: const Color(0xFF0A0A0F)),
            Positioned.fill(child: CustomPaint(painter: _FluidCanvasPainter(simulator: _fluidSimulator))),
            Center(
              child: Opacity(
                opacity: (sim.arousal / 100.0).clamp(0.3, 1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department, size: 80 + (sim.arousal * 0.4), color: const Color(0xFFFF2A6D)),
                    const SizedBox(height: 20),
                    const Text('GTA6HUB', style: TextStyle(fontSize: 28, color: Colors.white, letterSpacing: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('PROMETHEUS ACTIVE', style: TextStyle(fontSize: 12, color: const Color(0xFF00E5FF).withOpacity(0.7), letterSpacing: 6)),
                  ],
                ),
              ),
            ),
            const GTAHud(),
            // زر فتح قماش المخرج
            Positioned(
              top: 40, right: 10,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectorSandbox())),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFF2A6D))),
                  child: const Icon(Icons.dashboard_customize, color: Color(0xFFFF2A6D), size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FluidCanvasPainter extends CustomPainter {
  final FluidSimulator simulator;
  _FluidCanvasPainter({required this.simulator});
  @override
  void paint(Canvas canvas, Size size) => simulator.render(canvas);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
