import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/simulation_provider.dart';
import '../engine/fluids/fluid_simulator.dart';
import '../engine/fluids/fluid_emitter.dart';
import '../engine/cinematics/cinematic_impact_system.dart';
import 'gta_hud.dart';

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
    // إطلاق حلقة اللعبة الحية بسرعة 60 إطاراً في الثانية
    _ticker = createTicker((elapsed) {
      final simProvider = Provider.of<SimulationProvider>(context, listen: false);
      double delta = elapsed.inMilliseconds / 1000.0;
      
      // 1. تحديث معادلات الدماغ الحركية
      simProvider.update(delta);
      
      // 2. تحديث حركة جزيئات السوائل اللزجة
      _fluidSimulator.update(delta);

      // 3. مراقبة الذروة وضخ السوائل ديناميكياً عند التغيير
      if (simProvider.currentState == SimulationState.peak && _lastState != SimulationState.peak) {
        final origin = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2);
        final direction = const Offset(0, -1); // اندفاع للأعلى سينمائي
        
        // قذف دفعات السوائل بناءً على سرعة وعمق التحكم الحالي
        final newParticles = _fluidEmitter.emitCum(origin, direction, (simProvider.thrustSpeed / 50.0).clamp(0.5, 2.0));
        _fluidSimulator.emitParticles(newParticles);
      }
      
      _lastState = simProvider.currentState;
      setState(() {}); // إعادة رندرة لوحة الجزيئات
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
            // 1. الفضاء الداكن للمحاكاة
            Container(color: const Color(0xFF0A0A0F)),
            
            // 2. لوحة رسم السوائل الفيزيائية الحية (Fluid Canvas)
            Positioned.fill(
              child: CustomPaint(
                painter: _FluidCanvasPainter(simulator: _fluidSimulator),
              ),
            ),

            // 3. المؤشرات النيونية المركزية لـ GTA6HUB
            Center(
              child: Opacity(
                opacity: (sim.arousal / 100.0).clamp(0.3, 1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department, 
                      size: 80 + (sim.arousal * 0.4), // يتضخم الأيقونة مع الارتفاع الحركي
                      color: const Color(0xFFFF2A6D)
                    ),
                    const SizedBox(height: 20),
                    const Text('GTA6HUB', style: TextStyle(fontSize: 28, color: Colors.white, letterSpacing: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('PROMETHEUS ACTIVE', style: TextStyle(fontSize: 12, color: const Color(0xFF00E5FF).withOpacity(0.7), letterSpacing: 6)),
                  ],
                ),
              ),
            ),

            // 4. قمرة القيادة العلو والسفلية الـ HUD
            const GTAHud(),
          ],
        ),
      ),
    );
  }
}

// رسام مخصص لربط كافّة جزيئات السوائل بالـ Canvas الخاص بـ Flutter
class _FluidCanvasPainter extends CustomPainter {
  final FluidSimulator simulator;
  _FluidCanvasPainter({required this.simulator});

  @override
  void paint(Canvas canvas, Size size) {
    simulator.render(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
