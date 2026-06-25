import 'package:audioplayers/audioplayers.dart';
import '../core/simulation_provider.dart';

class AdaptiveAudioEngine {
  final AudioPlayer _breathLayer = AudioPlayer();
  final AudioPlayer _fluidLayer = AudioPlayer();
  final AudioPlayer _heartbeatLayer = AudioPlayer();
  bool _isEngineReady = false;
  SimulationState _lastState = SimulationState.idle;

  Future<void> initializeEngine() async {
    if (_isEngineReady) return;
    await _breathLayer.setReleaseMode(ReleaseMode.loop);
    await _heartbeatLayer.setReleaseMode(ReleaseMode.loop);
    await _fluidLayer.setReleaseMode(ReleaseMode.release);
    _isEngineReady = true;
  }

  void synchronizeAudio(SimulationState state, double arousal, double speed) async {
    if (!_isEngineReady) return;
    double playbackRate = 1.0 + (speed * 0.01).clamp(0.0, 1.0);
    await _breathLayer.setPlaybackRate(playbackRate);
    double heartbeatVolume = (arousal / 100.0).clamp(0.2, 1.0);
    await _heartbeatLayer.setVolume(heartbeatVolume);
    if (state != _lastState) { _lastState = state; _handleStateAudioTransition(state); }
  }

  void _handleStateAudioTransition(SimulationState state) async {
    switch (state) {
      case SimulationState.idle: await _breathLayer.setVolume(0.4); break;
      case SimulationState.active: await _breathLayer.setVolume(0.8); break;
      case SimulationState.peak: await _breathLayer.setVolume(1.0); break;
      case SimulationState.exhausted: await _breathLayer.setVolume(0.6); await _breathLayer.setPlaybackRate(0.8); break;
    }
  }

  Future<void> playFluidSquirtSound(double power) async {
    if (!_isEngineReady) return;
    await _fluidLayer.setVolume(power.clamp(0.5, 1.0));
  }

  void dispose() { _breathLayer.dispose(); _fluidLayer.dispose(); _heartbeatLayer.dispose(); }
}
