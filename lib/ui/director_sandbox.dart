import 'package:flutter/material.dart';
import '../engine/nodes/node_models.dart';
import '../engine/nodes/advanced_node_interpreter.dart';
import '../core/simulation_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

class DirectorSandbox extends StatefulWidget {
  const DirectorSandbox({Key? key}) : super(key: key);

  @override
  State<DirectorSandbox> createState() => _DirectorSandboxState();
}

class _DirectorSandboxState extends State<DirectorSandbox> {
  // قوائم العقد والأسلاك
  final List<AdvancedNodeData> _nodes = [];
  final List<NodeWire> _wires = [];
  
  // حالة التفاعل
  AdvancedNodeData? _selectedNode;
  Offset? _draggingWireStart;
  Offset? _draggingWireEnd;
  String? _draggingFromNodeId;
  String? _draggingFromSlotName;

  // المفسر الذي يربط كل شيء
  late AdvancedNodeInterpreter _interpreter;

  @override
  void initState() {
    super.initState();
    // إضافة بعض العقد الافتراضية للبدء
    _nodes.add(AdvancedNodeData(
      id: '1', position: const Offset(150, 300), label: 'On Peak', type: NodeType.trigger,
      inputs: [], outputs: [NodeSlot(name: 'Trigger', isInput: false)], internalValues: {},
    ));
    _nodes.add(AdvancedNodeData(
      id: '2', position: const Offset(450, 300), label: 'Emit Cum', type: NodeType.fluid,
      inputs: [NodeSlot(name: 'Execute', isInput: true)], outputs: [], internalValues: {},
    ));
    _nodes.add(AdvancedNodeData(
      id: '3', position: const Offset(450, 500), label: 'Shake Camera', type: NodeType.camera,
      inputs: [NodeSlot(name: 'Execute', isInput: true)], outputs: [], internalValues: {},
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
          // لوحة الرسم الرئيسية (Canvas)
          GestureDetector(
            onTapDown: (details) => _handleCanvasTap(details.localPosition),
            onPanUpdate: (details) => _handleNodeDrag(details.delta),
            onPanEnd: (details) => _handleDragEnd(),
            child: CustomPaint(
              painter: _SandboxPainter(
                nodes: _nodes,
                wires: _wires,
                selectedNode: _selectedNode,
                draggingWireStart: _draggingWireStart,
                draggingWireEnd: _draggingWireEnd,
              ),
              size: Size.infinite,
            ),
          ),

          // شريط العقد الجانبي (Node Palette)
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

          // زر التشغيل (Play)
          Positioned(
            bottom: 30, right: 30,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFFF2A6D),
              onPressed: () => _interpreter.evaluateAllTriggers(),
              child: const Icon(Icons.play_arrow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteButton(String label, NodeType type) {
    return GestureDetector(
      onTap: () {
        // إضافة عقدة جديدة عند النقر على الزر
        setState(() {
          _nodes.add(AdvancedNodeData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
            label: label.split(' ')[1],
            type: type,
            inputs: type != NodeType.trigger ? [NodeSlot(name: 'Execute', isInput: true)] : [],
            outputs: type == NodeType.trigger ? [NodeSlot(name: 'Trigger', isInput: false)] : [],
            internalValues: {},
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
      // فحص إذا ضغط على منفذ إخراج لعمل سلك جديد
      for (var node in _nodes) {
        for (var slot in node.outputs) {
          final slotPos = node.getSlotGlobalPosition(slot);
          if ((slotPos - position).distance < 15) {
            _draggingWireStart = slotPos;
            _draggingFromNodeId = node.id;
            _draggingFromSlotName = slot.name;
            _selectedNode = null;
            return;
          }
        }
      }
      
      // فحص إذا ضغط على عقدة لتحديدها
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
        // فحص إذا انتهى السلك على منفذ إدخال
        for (var node in _nodes) {
          for (var slot in node.inputs) {
            final slotPos = node.getSlotGlobalPosition(slot);
            if ((slotPos - _draggingWireEnd!).distance < 15) {
              _wires.add(NodeWire(fromNodeId: _draggingFromNodeId!, fromSlotName: _draggingFromSlotName!, toNodeId: node.id, toSlotName: slot.name));
              break;
            }
          }
        }
      }
      _draggingWireStart = null;
      _draggingWireEnd = null;
      _draggingFromNodeId = null;
      _draggingFromSlotName = null;
    });
  }
}

// رسام مخصص للوحة الرسم
class _SandboxPainter extends CustomPainter {
  final List<AdvancedNodeData> nodes;
  final List<NodeWire> wires;
  final AdvancedNodeData? selectedNode;
  final Offset? draggingWireStart;
  final Offset? draggingWireEnd;

  _SandboxPainter({required this.nodes, required this.wires, this.selectedNode, this.draggingWireStart, this.draggingWireEnd});

  @override
  void paint(Canvas canvas, Size size) {
    // رسم الأسلاك
    final wirePaint = Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (var wire in wires) {
      final fromNode = nodes.firstWhere((n) => n.id == wire.fromNodeId);
      final toNode = nodes.firstWhere((n) => n.id == wire.toNodeId);
      final fromSlot = fromNode.outputs.firstWhere((s) => s.name == wire.fromSlotName);
      final toSlot = toNode.inputs.firstWhere((s) => s.name == wire.toSlotName);
      _drawBezier(canvas, fromNode.getSlotGlobalPosition(fromSlot), toNode.getSlotGlobalPosition(toSlot), wirePaint);
    }
    // رسم السلك الجاري سحبه
    if (draggingWireStart != null && draggingWireEnd != null) {
      _drawBezier(canvas, draggingWireStart!, draggingWireEnd!, Paint()..color = const Color(0xFFFF2A6D)..strokeWidth = 2.0..style = PaintingStyle.stroke);
    }
    // رسم العقد
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
