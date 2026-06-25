import 'package:flutter/material.dart';
import '../engine/nodes/node_models.dart';
import '../engine/nodes/advanced_node_interpreter.dart';
import '../core/simulation_provider.dart';
import 'package:provider/provider.dart';

class DirectorSandbox extends StatefulWidget {
  const DirectorSandbox({Key? key}) : super(key: key);

  @override
  State<DirectorSandbox> createState() => _DirectorSandboxState();
}

class _DirectorSandboxState extends State<DirectorSandbox> {
  final List<AdvancedNodeData> _nodes = [];
  final List<NodeWire> _wires = [];
  
  AdvancedNodeData? _selectedNode;
  Offset? _draggingWireStart;
  Offset? _draggingWireEnd;
  String? _draggingFromNodeId;
  String? _draggingFromSlotName;

  // متحكمات لوحة الخصائص
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  late AdvancedNodeInterpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _nodes.add(AdvancedNodeData(
      id: '1', position: const Offset(150, 300), label: 'On Peak', type: NodeType.trigger,
      inputs: [], outputs: [NodeSlot(name: 'Trigger', isInput: false)], internalValues: {},
    ));
    _nodes.add(AdvancedNodeData(
      id: '2', position: const Offset(450, 300), label: 'Emit Cum', type: NodeType.fluid,
      inputs: [NodeSlot(name: 'Execute', isInput: true)], outputs: [], internalValues: {'power': 1.0},
    ));
    _nodes.add(AdvancedNodeData(
      id: '3', position: const Offset(450, 500), label: 'Shake Camera', type: NodeType.camera,
      inputs: [NodeSlot(name: 'Execute', isInput: true)], outputs: [], internalValues: {'intensity': 1.0},
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sim = Provider.of<SimulationProvider>(context, listen: false);
    _interpreter = AdvancedNodeInterpreter(simProvider: sim, nodes: _nodes, wires: _wires);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // لوحة الرسم (Canvas)
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

          // شريط العقد (Node Palette)
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

          // زر التشغيل
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFFF2A6D),
              onPressed: () => _interpreter.evaluateAllTriggers(),
              child: const Icon(Icons.play_arrow),
            ),
          ),

          // لوحة الخصائص (Property Panel) - تظهر عند تحديد عقدة
          if (_selectedNode != null)
            Positioned(
              left: 10, bottom: 30,
              child: _buildPropertyPanel(),
            ),
        ],
      ),
    );
  }

  // --- لوحة الخصائص الديناميكية ---
  Widget _buildPropertyPanel() {
    final node = _selectedNode!;
    _labelController.text = node.label;
    
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
          // عنوان
          const Text('Properties', style: TextStyle(color: Color(0xFFFF2A6D), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // تعديل الاسم
          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Label',
              labelStyle: TextStyle(color: Colors.white54, fontSize: 10),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2A6D))),
            ),
            onChanged: (v) => setState(() => node.label = v),
          ),
          const SizedBox(height: 12),
          // عرض / تعديل القيم الداخلية
          ...node.internalValues.keys.map((key) {
            _valueController.text = node.internalValues[key].toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _valueController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: key,
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2A6D))),
                ),
                onChanged: (v) => setState(() {
                  // محاولة تحويل القيمة إلى double
                  final parsed = double.tryParse(v);
                  if (parsed != null) node.internalValues[key] = parsed;
                }),
              ),
            );
          }),
          const SizedBox(height: 12),
          // زر الحذف
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.3)),
              onPressed: () => setState(() {
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
          _nodes.add(AdvancedNodeData(
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
        if ((node.position - position).distance < 60) {
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
            if ((node.getSlotGlobalPosition(slot) - _draggingWireEnd!).distance < 15) {
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

// --- رسام لوحة الرسم (بدون تغيير) ---
class _SandboxPainter extends CustomPainter {
  final List<AdvancedNodeData> nodes;
  final List<NodeWire> wires;
  final AdvancedNodeData? selectedNode;
  final Offset? draggingWireStart;
  final Offset? draggingWireEnd;

  _SandboxPainter({required this.nodes, required this.wires, this.selectedNode, this.draggingWireStart, this.draggingWireEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (var wire in wires) {
      final fromNode = nodes.firstWhere((n) => n.id == wire.fromNodeId);
      final toNode = nodes.firstWhere((n) => n.id == wire.toNodeId);
      final fromSlot = fromNode.outputs.firstWhere((s) => s.name == wire.fromSlotName);
      final toSlot = toNode.inputs.firstWhere((s) => s.name == wire.toSlotName);
      _drawBezier(canvas, fromNode.getSlotGlobalPosition(fromSlot), toNode.getSlotGlobalPosition(toSlot), wirePaint);
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
