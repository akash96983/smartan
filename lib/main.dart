import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keypoints Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const KeypointsDetectionPage(),
    );
  }
}

class KeypointsDetectionPage extends StatefulWidget {
  const KeypointsDetectionPage({super.key});

  @override
  State<KeypointsDetectionPage> createState() => _KeypointsDetectionPageState();
}

class _KeypointsDetectionPageState extends State<KeypointsDetectionPage> {
  File? _imageFile;
  ui.Image? _uiImage;
  List<PoseLandmark>? _landmarks;
  String? _keypointsJson;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _keypointsJson = null;
        _landmarks = null;
        _uiImage = null;
      });
      await _loadUiImage(File(pickedFile.path));
      await _detectKeypoints(File(pickedFile.path));
    }
  }

  Future<void> _loadUiImage(File imageFile) async {
    final data = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    setState(() {
      _uiImage = frame.image;
    });
  }

  Future<void> _detectKeypoints(File imageFile) async {
    setState(() {
      _loading = true;
    });
    try {
      final poseDetector = PoseDetector(options: PoseDetectorOptions());
      final inputImage = InputImage.fromFile(imageFile);
      final poses = await poseDetector.processImage(inputImage);
      await poseDetector.close();
      if (poses.isNotEmpty) {
        final landmarks = poses.first.landmarks.values
            .where((l) => l.likelihood > 0.1)
            .toList();
        setState(() {
          _landmarks = landmarks;
          _keypointsJson = jsonEncode({
            for (var l in landmarks)
              l.type.name: {
                'x': l.x,
                'y': l.y,
                'z': l.z,
                'likelihood': l.likelihood,
              },
          });
        });
      } else {
        setState(() {
          _landmarks = [];
          _keypointsJson = 'No keypoints detected.';
        });
      }
    } catch (e) {
      setState(() {
        _keypointsJson = 'Error: $e';
        _landmarks = null;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keypoints Detection')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_uiImage != null)
              SizedBox(
                height: 300,
                child: CustomPaint(
                  foregroundPainter: _landmarks != null
                      ? KeypointsPainter(_landmarks!, _uiImage!)
                      : null,
                  child: SizedBox(
                    width: _uiImage!.width.toDouble(),
                    height: _uiImage!.height.toDouble(),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _uiImage!.width.toDouble(),
                        height: _uiImage!.height.toDouble(),
                        child: RawImage(image: _uiImage!),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (_keypointsJson != null && !_loading)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_keypointsJson!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class KeypointsPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final ui.Image image;
  KeypointsPainter(this.landmarks, this.image);

  // Define the skeleton connections as pairs of landmark indices
  static const List<List<PoseLandmarkType>> skeleton = [
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Arms
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Legs
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    // Face
    [PoseLandmarkType.leftEye, PoseLandmarkType.rightEye],
    [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
    [PoseLandmarkType.rightEar, PoseLandmarkType.rightEye],
    [PoseLandmarkType.nose, PoseLandmarkType.leftEye],
    [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
  ];
  

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;
    final linePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Calculate scale to fit image in the widget
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (size.width - image.width * scale) / 2;
    final dy = (size.height - image.height * scale) / 2;

    // Map landmark type to Offset
    final Map<PoseLandmarkType, Offset> points = {
      for (final l in landmarks)
        l.type: Offset(l.x * scale + dx, l.y * scale + dy),
    };

    // Draw skeleton lines
    for (final connection in skeleton) {
      final p1 = points[connection[0]];
      final p2 = points[connection[1]];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    // Draw keypoints
    for (final offset in points.values) {
      canvas.drawCircle(offset, 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
