import 'dart:ui';

enum NodeType { trigger, action, fluid, audio, camera }

class NodeSlot {
  final String name;
  final bool isInput;
  Offset relativePosition = Offset.zero;
  NodeSlot({required this.name, required this.isInput});
}

class AdvancedNodeData {
  final String id;
  Offset position;
  final String label;
  final NodeType type;
  final List<NodeSlot> inputs;
  final List<NodeSlot> outputs;
  final Map<String, dynamic> internalValues;
  AdvancedNodeData({required this.id, required this.position, required this.label, required this.type, required this.inputs, required this.outputs, required this.internalValues});
  Offset getSlotGlobalPosition(NodeSlot slot) => position + slot.relativePosition;
}

class NodeWire {
  final String fromNodeId, fromSlotName, toNodeId, toSlotName;
  NodeWire({required this.fromNodeId, required this.fromSlotName, required this.toNodeId, required this.toSlotName});
}
