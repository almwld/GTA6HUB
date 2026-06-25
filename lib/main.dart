import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/simulation_provider.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SimulationProvider(),
      child: const GTA6App(),
    ),
  );
}

class GTA6App extends StatelessWidget {
  const GTA6App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTA6HUB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFFFF2A6D),
      ),
      home: const HomeScreen(),
    );
  }
}
