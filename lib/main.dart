import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'models/keypoint_entry.dart';
import 'services/db_service.dart';
import 'services/cloudinary_service.dart';
import 'services/firebase_service.dart';
import 'services/logger_service.dart';
import 'screens/history_screen.dart';

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
      home: const HomeNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [KeypointsDetectionPage(), HistoryScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
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
  bool _syncing = false;

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
    } catch (e, st) {
      LoggerService.logError('Error detecting keypoints', e, st);
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

  Future<void> _saveLocally() async {
    if (_imageFile == null || _keypointsJson == null) return;
    setState(() {
      _syncing = true;
    });
    try {
      final entry = KeypointEntry(
        keypointsJson: _keypointsJson!,
        imagePath: _imageFile!.path,
        timestamp: DateTime.now(),
      );
      await DBService().insertEntry(entry);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved locally.')));
    } catch (e, st) {
      LoggerService.logError('Error saving locally', e, st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving locally.')));
    } finally {
      setState(() {
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keypoints Detection')),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('Gallery'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_uiImage != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 260,
                              child: _uiImage != null
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        final displayWidth =
                                            constraints.maxWidth;
                                        final displayHeight =
                                            constraints.maxHeight;
                                        final imageAspect =
                                            _uiImage!.width / _uiImage!.height;
                                        double fittedWidth, fittedHeight;
                                        if (displayWidth / displayHeight >
                                            imageAspect) {
                                          fittedHeight = displayHeight;
                                          fittedWidth =
                                              displayHeight * imageAspect;
                                        } else {
                                          fittedWidth = displayWidth;
                                          fittedHeight =
                                              displayWidth / imageAspect;
                                        }
                                        return Center(
                                          child: SizedBox(
                                            width: fittedWidth,
                                            height: fittedHeight,
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: RawImage(
                                                    image: _uiImage!,
                                                  ),
                                                ),
                                                if (_landmarks != null)
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: CustomPaint(
                                                      painter: KeypointsPainter(
                                                        _landmarks!,
                                                        _uiImage!,
                                                        fittedWidth,
                                                        fittedHeight,
                                                      ),
                                                      size: Size(
                                                        fittedWidth,
                                                        fittedHeight,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 12),
                            if (_keypointsJson != null && !_loading)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: SelectableText(
                                  _keypointsJson!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            if (_keypointsJson != null &&
                                !_loading &&
                                !_syncing)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save),
                                  onPressed: _saveLocally,
                                  label: const Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            if (_syncing)
                              const Padding(
                                padding: EdgeInsets.only(top: 10.0),
                                child: CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
  final double displayWidth;
  final double displayHeight;
  KeypointsPainter(
    this.landmarks,
    this.image,
    this.displayWidth,
    this.displayHeight,
  );

  static const List<List<PoseLandmarkType>> skeleton = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
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

    final scaleX = displayWidth / image.width;
    final scaleY = displayHeight / image.height;

    final Map<PoseLandmarkType, Offset> points = {
      for (final l in landmarks) l.type: Offset(l.x * scaleX, l.y * scaleY),
    };

    for (final connection in skeleton) {
      final p1 = points[connection[0]];
      final p2 = points[connection[1]];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    for (final offset in points.values) {
      canvas.drawCircle(offset, 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
