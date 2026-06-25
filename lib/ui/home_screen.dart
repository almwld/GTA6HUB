import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/simulation_provider.dart';
import '../engine/fluids/fluid_simulator.dart';
import '../engine/fluids/fluid_emitter.dart';
import '../engine/cinematics/cinematic_impact_system.dart';
import '../engine/cinematics/motion_recorder.dart';
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
  final MotionRecorder _motionRecorder = MotionRecorder();
  SimulationState _lastState = SimulationState.idle;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final sim = Provider.of<SimulationProvider>(context, listen: false);
      double delta = elapsed.inMilliseconds / 1000.0;
      
      // وضع التشغيل التلقائي (المسجل)
      if (sim.autoMode) {
        _motionRecorder.updatePlayback(delta);
        final frame = _motionRecorder.getFrameAtTime(_motionRecorder.playbackTime);
        if (frame != null) {
          sim.setSpeedDirect(frame.speed);
          sim.setDepthDirect(frame.depth);
          sim.changePosition(frame.position);
        }
      }
      
      sim.update(delta);
      _fluidSimulator.update(delta);
      
      // تسجيل الإطارات إذا كان التسجيل نشطًا
      if (_motionRecorder.isRecording) {
        _motionRecorder.recordFrame(sim.thrustSpeed, sim.thrustDepth, sim.currentPosition, delta);
      }
      
      if (sim.currentState == SimulationState.peak && _lastState != SimulationState.peak) {
        final origin = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2);
        final direction = const Offset(0, -1);
        final newParticles = _fluidEmitter.emitCum(origin, direction, (sim.thrustSpeed / 50.0).clamp(0.5, 2.0));
        _fluidSimulator.emitParticles(newParticles);
      }
      _lastState = sim.currentState;
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
                    // مؤشر التسجيل / التشغيل
                    if (_motionRecorder.isRecording)
                      const Text('🔴 REC', style: TextStyle(color: Colors.red, fontSize: 12, letterSpacing: 4)),
                    if (_motionRecorder.isPlaying)
                      const Text('▶️ PLAYING', style: TextStyle(color: Colors.green, fontSize: 12, letterSpacing: 4)),
                  ],
                ),
              ),
            ),
            // شريط التحكم بالتسجيل
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _recButton(Icons.fiber_manual_record, Colors.red, () {
                    if (_motionRecorder.isRecording) {
                      _motionRecorder.stopRecording();
                    } else {
                      _motionRecorder.startRecording();
                    }
                    setState(() {});
                  }, _motionRecorder.isRecording),
                  const SizedBox(width: 20),
                  _recButton(Icons.play_arrow, Colors.green, () {
                    if (_motionRecorder.isPlaying) {
                      _motionRecorder.stopPlayback();
                      sim.setAutoMode(false);
                    } else {
                      sim.setAutoMode(true);
                      _motionRecorder.startPlayback();
                    }
                    setState(() {});
                  }, _motionRecorder.isPlaying),
                ],
              ),
            ),
            const GTAHud(),
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

  Widget _recButton(IconData icon, Color color, VoidCallback onTap, bool active) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withOpacity(0.3) : Colors.black54,
          border: Border.all(color: color),
        ),
        child: Icon(icon, color: color, size: 24),
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
