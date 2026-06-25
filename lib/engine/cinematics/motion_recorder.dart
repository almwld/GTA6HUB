import 'dart:collection';

class MotionFrame {
  final double speed;
  final double depth;
  final String position;
  final double timestamp;

  MotionFrame({
    required this.speed,
    required this.depth,
    required this.position,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'speed': speed,
    'depth': depth,
    'position': position,
    'timestamp': timestamp,
  };

  factory MotionFrame.fromJson(Map<String, dynamic> json) => MotionFrame(
    speed: json['speed'] as double,
    depth: json['depth'] as double,
    position: json['position'] as String,
    timestamp: json['timestamp'] as double,
  );
}

class MotionRecorder {
  final ListQueue<MotionFrame> _frames = ListQueue<MotionFrame>();
  bool _isRecording = false;
  bool _isPlaying = false;
  int _playIndex = 0;
  double _recordingTime = 0.0;
  double _playbackTime = 0.0;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  double get recordingTime => _recordingTime;
  double get playbackTime => _playbackTime;
  int get frameCount => _frames.length;

  void startRecording() {
    _frames.clear();
    _isRecording = true;
    _recordingTime = 0.0;
  }

  void stopRecording() {
    _isRecording = false;
  }

  void recordFrame(double speed, double depth, String position, double delta) {
    if (!_isRecording) return;
    _recordingTime += delta;
    // نسجل كل 100 ميلي ثانية لتجنب تضخم البيانات
    if (_frames.isEmpty || _recordingTime - _frames.last.timestamp > 0.1) {
      _frames.add(MotionFrame(
        speed: speed,
        depth: depth,
        position: position,
        timestamp: _recordingTime,
      ));
    }
  }

  void startPlayback() {
    if (_frames.isEmpty) return;
    _isPlaying = true;
    _playIndex = 0;
    _playbackTime = 0.0;
  }

  void stopPlayback() {
    _isPlaying = false;
    _playIndex = 0;
    _playbackTime = 0.0;
  }

  MotionFrame? getFrameAtTime(double time) {
    if (_frames.isEmpty) return null;
    while (_playIndex < _frames.length - 1 && _frames.elementAt(_playIndex + 1).timestamp <= time) {
      _playIndex++;
    }
    return _frames.elementAt(_playIndex);
  }

  void updatePlayback(double delta) {
    if (!_isPlaying) return;
    _playbackTime += delta;
    if (_playbackTime > _frames.last.timestamp) {
      stopPlayback();
    }
  }
}
