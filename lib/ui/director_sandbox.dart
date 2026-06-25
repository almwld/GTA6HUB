import 'package:flutter/material.dart';
import '../engine/nodes/node_models.dart';
import '../engine/nodes/advanced_node_interpreter.dart';
import '../core/simulation_provider.dart';
import 'package:provider/provider.dart';

// فئة وسيطة محلية أو غلاف لتمكين تعديل الخصائص بدون كسر الفئات الأصلية الثابتة
class EditableNodeData {
  final String id;
  Offset position;
  String label;
  final NodeType type;
  final List<NodeSlot> inputs;
  final List<NodeSlot> outputs;
  final Map<String, dynamic> internalValues;

  EditableNodeData({
    required this.id,
    required this.position,
    required this.label,
    required this.type,
    required this.inputs,
    required this.outputs,
    required this.internalValues,
  });

  AdvancedNodeData toCoreNode() {
    return AdvancedNodeData(
      id: id,
      position: position,
      label: label,
      type: type,
      inputs: inputs,
      outputs: outputs,
      internalValues: internalValues,
    );
  }
  Offset getSlotGlobalPosition(NodeSlot slot) => position + slot.relativePosition;
}

class DirectorSandbox extends StatefulWidget {
  const DirectorSandbox({Key? key}) : super(key: key);

  @override
  State<DirectorSandbox> createState() => _DirectorSandboxState();
}

class _DirectorSandboxState extends State<DirectorSandbox> {
  final List<EditableNodeData> _nodes = [];
  final List<NodeWire> _wires = [];
  
  EditableNodeData? _selectedNode;
  Offset? _draggingWireStart;
  Offset? _draggingWireEnd;
  String? _draggingFromNodeId;
  String? _draggingFromSlotName;

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nodes.add(EditableNodeData(
      id: '1', position: const Offset(150, 300), label: 'On Peak', type: NodeType.trigger,
      inputs: [], outputs: [NodeSlot(name: 'Trigger', isInput: false)], internalValues: {},
    ));
    _nodes.add(EditableNodeData(
      id: '2', position: const Offset(450, 300), label: 'Emit Cum', type: NodeType.fluid,
      inputs: [NodeSlot(name: 'Execute', isInput: true)], outputs: [], internalValues: {'power': 1.0},
    ));
    _nodes.add(EditableNodeData(
      id: '3', position: const Offset(450, 500), label: 'Shake Camera', type: NodeType.camera,
      inputs: [NodeSlot(name: 'Execute', isInput: true)], outputs: [], internalValues: {'intensity': 1.0},
    ));
  }

  void _executeInterpreter() {
    final coreNodes = _nodes.map((n) => n.toCoreNode()).toList();
    final sim = Provider.of<SimulationProvider>(context, listen: false);
    final interpreter = AdvancedNodeInterpreter(simProvider: sim, nodes: coreNodes, wires: _wires);
    interpreter.evaluateAllTriggers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) => _handleCanvasTap(details.localPosition),
            onPanUpdate: (details) => _handleNodeDrag(details.delta),
            onPanEnd: (details) => _handleDragEnd(),
            child: CustomPaint(
              painter: _SandboxPainter(
                nodes: _nodes, wires: _wires, selectedNode: _selectedNode,
                draggingWireStart: _draggingWireStart, draggingWireEnd: _draggingWireEnd,
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            right: 10, top: 50,
            child: Column(
              children: [
                _paletteButton('⚡ Trigger', NodeType.trigger),
                _paletteButton('💧 Fluid', NodeType.fluid),
                _paletteButton('🔊 Audio', NodeType.audio),
                _paletteButton('📷 Camera', NodeType.camera),
              ],
            ),
          ),
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFFF2A6D),
              onPressed: _executeInterpreter,
              child: const Icon(Icons.play_arrow),
            ),
          ),
          if (_selectedNode != null)
            Positioned(
              left: 10, bottom: 30,
              child: _buildPropertyPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyPanel() {
    final node = _selectedNode!;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Properties', style: TextStyle(color: Color(0xFFFF2A6D), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController..text = node.label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Label',
              labelStyle: TextStyle(color: Colors.white54, fontSize: 10),
            ),
            onChanged: (v) => setState(() => node.label = v),
          ),
          const SizedBox(height: 12),
          ...node.internalValues.keys.map((key) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _valueController..text = node.internalValues[key].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(labelText: key),
                onChanged: (v) => setState(() {
                  final parsed = double.tryParse(v);
                  if (parsed != null) node.internalValues[key] = parsed;
                }),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.3)),
              onPressed: () => setState(() {
                _wires.removeWhere((w) => w.fromNodeId == node.id || w.toNodeId == node.id);
                _nodes.remove(node);
                _selectedNode = null;
              }),
              child: const Text('Delete Node', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteButton(String label, NodeType type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _nodes.add(EditableNodeData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
            label: label.split(' ')[1],
            type: type,
            inputs: type != NodeType.trigger ? [NodeSlot(name: 'Execute', isInput: true)] : [],
            outputs: type == NodeType.trigger ? [NodeSlot(name: 'Trigger', isInput: false)] : [],
            internalValues: type == NodeType.fluid ? {'power': 1.0} : (type == NodeType.camera ? {'intensity': 1.0} : {}),
          ));
        });
      },
      child: Container(
        width: 80, margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white24)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
      ),
    );
  }

  void _handleCanvasTap(Offset position) {
    setState(() {
      for (var node in _nodes) {
        for (var slot in node.outputs) {
          if ((node.getSlotGlobalPosition(slot) - position).distance < 15) {
            _draggingWireStart = node.getSlotGlobalPosition(slot);
            _draggingFromNodeId = node.id;
            _draggingFromSlotName = slot.name;
            _selectedNode = null;
            return;
          }
        }
      }
      bool hitNode = false;
      for (var node in _nodes) {
        if ((node.position - position).distance < 40) {
          _selectedNode = node;
          hitNode = true;
          break;
        }
      }
      if (!hitNode) _selectedNode = null;
    });
  }

  void _handleNodeDrag(Offset delta) {
    setState(() {
      if (_draggingWireStart != null) {
        _draggingWireEnd = (_draggingWireEnd ?? _draggingWireStart!) + delta;
      } else if (_selectedNode != null) {
        _selectedNode!.position += delta;
      }
    });
  }

  void _handleDragEnd() {
    setState(() {
      if (_draggingWireStart != null && _draggingWireEnd != null) {
        for (var node in _nodes) {
          for (var slot in node.inputs) {
            if ((node.getSlotGlobalPosition(slot) - _draggingWireEnd!).distance < 25) {
              _wires.add(NodeWire(fromNodeId: _draggingFromNodeId!, fromSlotName: _draggingFromSlotName!, toNodeId: node.id, toSlotName: slot.name));
              break;
            }
          }
        }
      }
      _draggingWireStart = null; _draggingWireEnd = null;
      _draggingFromNodeId = null; _draggingFromSlotName = null;
    });
  }
}

class _SandboxPainter extends CustomPainter {
  final List<EditableNodeData> nodes;
  final List<NodeWire> wires;
  final EditableNodeData? selectedNode;
  final Offset? draggingWireStart;
  final Offset? draggingWireEnd;

  _SandboxPainter({required this.nodes, required this.wires, this.selectedNode, this.draggingWireStart, this.draggingWireEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (var wire in wires) {
      final fromNode = nodes.firstWhere((n) => n.id == wire.fromNodeId);
      final toNode = nodes.firstWhere((n) => n.id == wire.toNodeId);
      _drawBezier(canvas, fromNode.position, toNode.position, wirePaint);
    }
    if (draggingWireStart != null && draggingWireEnd != null) {
      _drawBezier(canvas, draggingWireStart!, draggingWireEnd!, Paint()..color = const Color(0xFFFF2A6D)..strokeWidth = 2.0..style = PaintingStyle.stroke);
    }
    for (var node in nodes) {
      final bgPaint = Paint()..color = (node == selectedNode) ? Colors.purple : Colors.blueGrey;
      canvas.drawCircle(node.position, 30, bgPaint);
      final tp = TextPainter(text: TextSpan(text: node.label, style: const TextStyle(color: Colors.white, fontSize: 10)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, node.position - Offset(tp.width/2, tp.height/2));
    }
  }

  void _drawBezier(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()..moveTo(start.dx, start.dy);
    double ctrl = (end.dx - start.dx).abs() / 2;
    path.cubicTo(start.dx + ctrl, start.dy, end.dx - ctrl, end.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
