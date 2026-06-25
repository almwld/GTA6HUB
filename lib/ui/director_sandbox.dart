import 'package:flutter/material.dart';
import '../engine/nodes/node_models.dart';
import '../engine/nodes/advanced_node_interpreter.dart';
import '../core/simulation_provider.dart';
import '../engine/cinematics/motion_recorder.dart';
import 'package:provider/provider.dart';

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

  AdvancedNodeData toCoreNode() => AdvancedNodeData(
        id: id, position: position, label: label, type: type,
        inputs: inputs, outputs: outputs, internalValues: internalValues,
      );

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
  List<SavedSequence> _savedSequences = [];

  @override
  void initState() {
    super.initState();
    _loadSequences();
    _nodes.add(EditableNodeData(
      id: '1', position: const Offset(150, 300), label: 'On Peak', type: NodeType.trigger,
      inputs: [], outputs: [NodeSlot(name: 'Trigger', isInput: false)], internalValues: {},
    ));
  }

  Future<void> _loadSequences() async {
    _savedSequences = await MotionRecorder.loadAllSequences();
    setState(() {});
  }

  void _executeInterpreter() {
    final coreNodes = _nodes.map((n) => n.toCoreNode()).toList();
    final sim = Provider.of<SimulationProvider>(context, listen: false);
    final interpreter = AdvancedNodeInterpreter(
      simProvider: sim, nodes: coreNodes, wires: _wires,
      onPlaySequence: (id) {
        try {
          final index = int.parse(id);
          if (index >= 0 && index < _savedSequences.length) {
            final seq = _savedSequences[index];
            sim.setAutoMode(true);
            print("▶️ Playing saved sequence: ${seq.name}");
          }
        } catch (_) {}
      },
    );
    interpreter.evaluateAllTriggers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (d) => _handleCanvasTap(d.localPosition),
            onPanUpdate: (d) => _handleNodeDrag(d.delta),
            onPanEnd: (d) => _handleDragEnd(),
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
                _paletteButton('⚡ Trigger', NodeType.trigger, {}),
                _paletteButton('💧 Fluid', NodeType.fluid, {'power': 1.0}),
                _paletteButton('📷 Camera', NodeType.camera, {'intensity': 1.0}),
                _paletteButton('▶️ Play Seq', NodeType.action, {'seq_id': '0'}),
                _paletteButton('🔊 Moan', NodeType.audio, {'volume': 0.8}),
                _paletteButton('🗣️ Scream', NodeType.audio, {'volume': 1.0}),
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
          if (_selectedNode != null) Positioned(left: 10, bottom: 30, child: _buildPropertyPanel()),
        ],
      ),
    );
  }

  Widget _buildPropertyPanel() {
    final node = _selectedNode!;
    _labelController.text = node.label;
    return Container(
      width: 280, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.5))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Properties', style: TextStyle(color: Color(0xFFFF2A6D), fontSize: 14)),
          const SizedBox(height: 12),
          TextField(controller: _labelController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: 'Label'), onChanged: (v) => setState(() => node.label = v)),
          if (node.label == 'Play Seq') ...[
            const Text('Saved Sequences:', style: TextStyle(color: Colors.white54, fontSize: 10)),
            ..._savedSequences.asMap().entries.map((e) => GestureDetector(
                  onTap: () => setState(() => node.internalValues['seq_id'] = e.key.toString()),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: node.internalValues['seq_id'] == e.key.toString() ? const Color(0xFFFF2A6D).withOpacity(0.3) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                    child: Text('🎬 ${e.value.name}', style: TextStyle(color: node.internalValues['seq_id'] == e.key.toString() ? Colors.white : Colors.white70)),
                  ),
                )),
          ],
          ...node.internalValues.keys.where((k) => k != 'seq_id').map((key) {
            _valueController.text = node.internalValues[key].toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(controller: _valueController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: InputDecoration(labelText: key), onChanged: (v) => setState(() { final p = double.tryParse(v); if (p != null) node.internalValues[key] = p; })),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.3)), onPressed: () => setState(() { _wires.removeWhere((w) => w.fromNodeId == node.id || w.toNodeId == node.id); _nodes.remove(node); _selectedNode = null; }), child: const Text('Delete', style: TextStyle(color: Colors.red)))),
        ],
      ),
    );
  }

  Widget _paletteButton(String l, NodeType t, Map<String, dynamic> d) => GestureDetector(
        onTap: () => setState(() => _nodes.add(EditableNodeData(id: DateTime.now().millisecondsSinceEpoch.toString(), position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2), label: l.split(' ')[1], type: t, inputs: t != NodeType.trigger ? [NodeSlot(name: 'Execute', isInput: true)] : [], outputs: t == NodeType.trigger ? [NodeSlot(name: 'Trigger', isInput: false)] : [], internalValues: Map<String, dynamic>.from(d)))),
        child: Container(width: 80, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white24)), child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center)),
      );

  void _handleCanvasTap(Offset p) => setState(() {
        for (var n in _nodes) for (var s in n.outputs) if ((n.getSlotGlobalPosition(s) - p).distance < 15) { _draggingWireStart = n.getSlotGlobalPosition(s); _draggingFromNodeId = n.id; _draggingFromSlotName = s.name; _selectedNode = null; return; }
        bool hit = false; for (var n in _nodes) if ((n.position - p).distance < 40) { _selectedNode = n; hit = true; break; } if (!hit) _selectedNode = null;
      });
  void _handleNodeDrag(Offset d) => setState(() { if (_draggingWireStart != null) _draggingWireEnd = (_draggingWireEnd ?? _draggingWireStart!) + d; else if (_selectedNode != null) _selectedNode!.position += d; });
  void _handleDragEnd() => setState(() { if (_draggingWireStart != null && _draggingWireEnd != null) { for (var n in _nodes) for (var s in n.inputs) if ((n.getSlotGlobalPosition(s) - _draggingWireEnd!).distance < 25) { _wires.add(NodeWire(fromNodeId: _draggingFromNodeId!, fromSlotName: _draggingFromSlotName!, toNodeId: n.id, toSlotName: s.name)); break; } } _draggingWireStart = null; _draggingWireEnd = null; _draggingFromNodeId = null; _draggingFromSlotName = null; });
}

class _SandboxPainter extends CustomPainter {
  final List<EditableNodeData> nodes; final List<NodeWire> wires; final EditableNodeData? selectedNode; final Offset? draggingWireStart; final Offset? draggingWireEnd;
  _SandboxPainter({required this.nodes, required this.wires, this.selectedNode, this.draggingWireStart, this.draggingWireEnd});
  @override
  void paint(Canvas c, Size s) {
    final wp = Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (var w in wires) { final fn = nodes.firstWhere((n) => n.id == w.fromNodeId); final tn = nodes.firstWhere((n) => n.id == w.toNodeId); _bezier(c, fn.position, tn.position, wp); }
    if (draggingWireStart != null && draggingWireEnd != null) _bezier(c, draggingWireStart!, draggingWireEnd!, Paint()..color = const Color(0xFFFF2A6D)..strokeWidth = 2.0..style = PaintingStyle.stroke);
    for (var n in nodes) { c.drawCircle(n.position, 30, Paint()..color = (n == selectedNode) ? Colors.purple : Colors.blueGrey); final tp = TextPainter(text: TextSpan(text: n.label, style: const TextStyle(color: Colors.white, fontSize: 10)), textDirection: TextDirection.ltr)..layout(); tp.paint(c, n.position - Offset(tp.width / 2, tp.height / 2)); }
  }
  void _bezier(Canvas c, Offset a, Offset b, Paint p) { final ph = Path()..moveTo(a.dx, a.dy); double ctrl = (b.dx - a.dx).abs() / 2; ph.cubicTo(a.dx + ctrl, a.dy, b.dx - ctrl, b.dy, b.dx, b.dy); c.drawPath(ph, p); }
  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}
