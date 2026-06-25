import 'node_models.dart';
import '../core/simulation_provider.dart';

class AdvancedNodeInterpreter {
  final SimulationProvider _simProvider;
  final List<AdvancedNodeData> _nodes;
  final List<NodeWire> _wires;
  final Map<String, DateTime> _lastFiredTime = {};
  final Map<String, int> _coolDownDuration = {
    "Emit Cum": 2500, "Play Scream": 3000, "Shake Camera": 800, "Play Seq": 5000,
  };
  final Function(String)? onPlaySequence;

  AdvancedNodeInterpreter({
    required SimulationProvider simProvider,
    required List<AdvancedNodeData> nodes,
    required List<NodeWire> wires,
    this.onPlaySequence,
  })  : _simProvider = simProvider, _nodes = nodes, _wires = wires;

  void evaluateAllTriggers() {
    for (var node in _nodes) {
      if (node.type == NodeType.trigger) {
        bool conditionMet = false;
        if (node.label == "On Peak" && _simProvider.currentState == SimulationState.peak) conditionMet = true;
        if (node.label == "On Active" && _simProvider.currentState == SimulationState.active) conditionMet = true;
        if (conditionMet) _propagateSignalFromTrigger(node);
      }
    }
  }

  void _propagateSignalFromTrigger(AdvancedNodeData triggerNode) {
    for (var slot in triggerNode.outputs) {
      for (var wire in _wires) {
        if (wire.fromNodeId == triggerNode.id && wire.fromSlotName == slot.name) {
          final targetNode = _findNodeById(wire.toNodeId);
          if (targetNode != null) _executeAction(targetNode, _simProvider.arousal);
        }
      }
    }
  }

  void _executeAction(AdvancedNodeData actionNode, double kineticPayload) {
    final nodeId = actionNode.id; final label = actionNode.label; final now = DateTime.now();
    if (_lastFiredTime.containsKey(nodeId)) {
      final lastTime = _lastFiredTime[nodeId]!;
      final cooldown = _coolDownDuration[label] ?? 500;
      if (now.difference(lastTime).inMilliseconds < cooldown) return;
    }
    _lastFiredTime[nodeId] = now;
    switch (label) {
      case "Emit Cum": print("💦 Emitting Cum! (power: ${(kineticPayload / 100.0).clamp(0.1, 1.0)})"); break;
      case "Shake Camera": print("📳 Shaking Camera! (intensity: ${actionNode.internalValues['intensity'] ?? 1.0})"); break;
      case "Play Seq":
        final seqId = actionNode.internalValues['seq_id']?.toString() ?? '0';
        print("▶️ Interpreter: Triggering Play Sequence ID: $seqId");
        onPlaySequence?.call(seqId);
        break;
      default: print("❓ Unknown action: $label");
    }
  }

  AdvancedNodeData? _findNodeById(String id) {
    try { return _nodes.firstWhere((n) => n.id == id); } catch (_) { return null; }
  }
}
