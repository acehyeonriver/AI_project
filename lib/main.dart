import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PoseScreen());
  }
}

class PoseScreen extends StatefulWidget {
  @override
  State<PoseScreen> createState() => _PoseScreenState();
}

class _PoseScreenState extends State<PoseScreen> {
  html.VideoElement? _videoElement;
  List<Map<String, dynamic>> keypoints = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    Timer.periodic(Duration(seconds: 1), (_) => _sendFrameToServer());
  }

  void _initializeCamera() {
    _videoElement = html.VideoElement()
      ..width = 640
      ..height = 480
      ..autoplay = true;

    html.window.navigator.mediaDevices?.getUserMedia({
      'video': {'facingMode': 'user'}
    }).then((stream) {
      _videoElement!.srcObject = stream;
    });

    html.document.body!.append(_videoElement!);
  }

  Future<void> _sendFrameToServer() async {
    final canvas = html.CanvasElement(width: 640, height: 480);
    final ctx = canvas.context2D;
    ctx.drawImage(_videoElement!, 0, 0);

    final blob = await canvas.toBlob("image/jpeg");
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob!);

    await reader.onLoad.first;
    final buffer = reader.result as List<int>;

    final uri = Uri.parse("http://YOUR_SERVER_IP:8000/pose");
    final request = http.MultipartRequest("POST", uri);
    request.files.add(http.MultipartFile.fromBytes("file", buffer, filename: "frame.jpg"));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);
    setState(() {
      keypoints = List<Map<String, dynamic>>.from(data['keypoints']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          HtmlElementView(viewType: 'videoElement'),
          CustomPaint(
            painter: PosePainter(keypoints),
            size: Size(640, 480),
          )
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Map<String, dynamic>> keypoints;

  PosePainter(this.keypoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.fill;

    for (var p in keypoints) {
      if (p['visibility'] > 0.5) {
        canvas.drawCircle(
          Offset(p['x'] * size.width, p['y'] * size.height),
          4,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) =>
      oldDelegate.keypoints != keypoints;
}
