import 'package:audioplayers/audioplayers.dart';

class SpatialAudioEngine {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    _isInitialized = true;
  }

  Future<void> playMoan(double intensity, double speed) async {
    if (!_isInitialized) return;
    await _player.setVolume(intensity.clamp(0.2, 1.0));
    await _player.setPlaybackRate((1.0 + speed * 0.01).clamp(0.8, 2.0));
    // await _player.play(AssetSource('audio/moans/moan_01.mp3'));
  }

  Future<void> playScream() async {
    if (!_isInitialized) await init();
    await _player.setVolume(1.0);
    await _player.setPlaybackRate(1.0);
    // await _player.play(AssetSource('audio/screams/climax_01.mp3'));
  }

  void dispose() => _player.dispose();
}
