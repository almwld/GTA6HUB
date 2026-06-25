import 'dart:collection';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    speed: (json['speed'] as num).toDouble(),
    depth: (json['depth'] as num).toDouble(),
    position: json['position'] as String,
    timestamp: (json['timestamp'] as num).toDouble(),
  );
}

class SavedSequence {
  final String name;
  final double duration;
  final int frameCount;
  final List<MotionFrame> frames;

  SavedSequence({
    required this.name,
    required this.duration,
    required this.frameCount,
    required this.frames,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration': duration,
    'frameCount': frameCount,
    'frames': frames.map((f) => f.toJson()).toList(),
  };

  factory SavedSequence.fromJson(Map<String, dynamic> json) => SavedSequence(
    name: json['name'] as String,
    duration: (json['duration'] as num).toDouble(),
    frameCount: (json['frameCount'] as num).toInt(),
    frames: (json['frames'] as List).map((f) => MotionFrame.fromJson(f as Map<String, dynamic>)).toList(),
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

  static const String _storageKey = 'saved_sequences';

  Future<void> saveCurrentSequence(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final sequence = SavedSequence(
      name: name,
      duration: _recordingTime,
      frameCount: _frames.length,
      frames: _frames.toList(),
    );
    final existingJson = prefs.getStringList(_storageKey) ?? [];
    existingJson.add(jsonEncode(sequence.toJson()));
    await prefs.setStringList(_storageKey, existingJson);
  }

  static Future<List<SavedSequence>> loadAllSequences() async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getStringList(_storageKey) ?? [];
    return existingJson
        .map((j) => SavedSequence.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteSequence(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getStringList(_storageKey) ?? [];
    if (index >= 0 && index < existingJson.length) {
      existingJson.removeAt(index);
      await prefs.setStringList(_storageKey, existingJson);
    }
  }

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
    if (_frames.isEmpty || _recordingTime - _frames.last.timestamp > 0.1) {
      _frames.add(MotionFrame(
        speed: speed,
        depth: depth,
        position: position,
        timestamp: _recordingTime,
      ));
    }
  }

  void loadSequence(SavedSequence sequence) {
    _frames.clear();
    _frames.addAll(sequence.frames);
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
