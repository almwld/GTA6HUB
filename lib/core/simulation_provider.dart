import 'package:flutter/material.dart';

enum SimulationState { idle, active, peak, exhausted }

class SimulationProvider with ChangeNotifier {
  SimulationState _currentState = SimulationState.idle;
  double _arousal = 0.0;
  double _stamina = 100.0;
  double _thrustSpeed = 20.0;
  double _thrustDepth = 30.0;
  String _currentPosition = "Missionary";
  String _partnerName = "Elena";
  String _currentTime = "22:00";
  bool _autoMode = false;

  SimulationState get currentState => _currentState;
  double get arousal => _arousal;
  double get stamina => _stamina;
  double get thrustSpeed => _thrustSpeed;
  double get thrustDepth => _thrustDepth;
  String get currentPosition => _currentPosition;
  String get partnerName => _partnerName;
  String get currentTime => _currentTime;
  bool get autoMode => _autoMode;

  // دوال جديدة للتحكم التلقائي (للمسجل)
  void setAutoMode(bool v) { _autoMode = v; notifyListeners(); }
  void setSpeedDirect(double v) { _thrustSpeed = v.clamp(0.0, 100.0); }
  void setDepthDirect(double v) { _thrustDepth = v.clamp(0.0, 100.0); }

  void increaseSpeed() { _thrustSpeed = (_thrustSpeed + 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void decreaseSpeed() { _thrustSpeed = (_thrustSpeed - 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void increaseDepth() { _thrustDepth = (_thrustDepth + 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void decreaseDepth() { _thrustDepth = (_thrustDepth - 10.0).clamp(0.0, 100.0); notifyListeners(); }
  void changePosition(String pos) { _currentPosition = pos; notifyListeners(); }

  void update(double delta) {
    double effort = (_thrustSpeed * 0.4) + (_thrustDepth * 0.6);
    if (_currentState == SimulationState.exhausted) {
      _stamina = (_stamina + 8.0 * delta).clamp(0.0, 100.0);
      _arousal = (_arousal - 12.0 * delta).clamp(0.0, 100.0);
      if (_stamina >= 40.0) _currentState = SimulationState.idle;
    } else if (effort > 10.0) {
      double growthModifier = 1.0 + (_arousal * 0.015);
      _arousal = (_arousal + effort * 0.02 * growthModifier * delta).clamp(0.0, 100.0);
      _stamina = (_stamina - effort * 0.05 * (1.0 + _thrustSpeed * 0.01) * delta).clamp(0.0, 100.0);
    } else {
      _arousal = (_arousal - 3.0 * delta).clamp(0.0, 100.0);
      _stamina = (_stamina + 2.0 * delta).clamp(0.0, 100.0);
    }
    if (_stamina <= 0) _currentState = SimulationState.exhausted;
    else if (_arousal >= 90) _currentState = SimulationState.peak;
    else if (_arousal > 20) _currentState = SimulationState.active;
    else _currentState = SimulationState.idle;
    if (!_autoMode) notifyListeners();
  }
}
