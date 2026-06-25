import 'package:flutter/material.dart';

enum SimulationState { idle, active, peak, exhausted }

class SimulationProvider with ChangeNotifier {
  SimulationState _currentState = SimulationState.idle;
  double _arousal = 0.0;
  double _stamina = 100.0;
  double _thrustSpeed = 20.0;
  double _thrustDepth = 30.0;
  String _currentPosition = "Missionary";

  SimulationState get currentState => _currentState;
  double get arousal => _arousal;
  double get stamina => _stamina;
  double get thrustSpeed => _thrustSpeed;
  double get thrustDepth => _thrustDepth;
  String get currentPosition => _currentPosition;

  void increaseSpeed() { _thrustSpeed = (_thrustSpeed + 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void decreaseSpeed() { _thrustSpeed = (_thrustSpeed - 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void increaseDepth() { _thrustDepth = (_thrustDepth + 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void decreaseDepth() { _thrustDepth = (_thrustDepth - 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void changePosition(String pos) { _currentPosition = pos; notifyListeners(); }

  void update(double delta) {
    double effort = (_thrustSpeed * 0.4) + (_thrustDepth * 0.6);
    if (effort > 10.0) {
      _arousal = (_arousal + effort * 0.02 * delta).clamp(0.0, 100.0);
      _stamina = (_stamina - effort * 0.05 * delta).clamp(0.0, 100.0);
    } else {
      _arousal = (_arousal - 3.0 * delta).clamp(0.0, 100.0);
      _stamina = (_stamina + 2.0 * delta).clamp(0.0, 100.0);
    }
    if (_stamina <= 0) _currentState = SimulationState.exhausted;
    else if (_arousal >= 90) _currentState = SimulationState.peak;
    else if (_arousal > 20) _currentState = SimulationState.active;
    else _currentState = SimulationState.idle;
    notifyListeners();
  }
}
