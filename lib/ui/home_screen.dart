import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/simulation_provider.dart';
import 'gta_hud.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final _simProvider = SimulationProvider();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _simProvider.update(elapsed.inMilliseconds / 1000.0);
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
    return Scaffold(
      body: Stack(
        children: [
          // خلفية
          Container(color: const Color(0xFF0A0A0F)),
          // شاشة المحاكاة
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, size: 80, color: Color(0xFFFF2A6D)),
                const SizedBox(height: 20),
                Text('GTA6HUB', style: TextStyle(fontSize: 28, color: Colors.white, letterSpacing: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('PROMETHEUS ENGINE', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 8)),
              ],
            ),
          ),
          // واجهة HUD
          const GTAHud(),
        ],
      ),
    );
  }
}
