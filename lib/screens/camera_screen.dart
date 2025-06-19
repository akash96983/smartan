import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/keypoint_entry.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../services/logger_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _imageFile;
  String? _keypointsJson;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _keypointsJson = null;
      });
    }
  }

  Future<void> _analyzeAndSave() async {
    if (_imageFile == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final keypointsJson = await ApiService.getKeypointsFromBackend(
        _imageFile!,
      );
      if (keypointsJson != null) {
        final entry = KeypointEntry(
          keypointsJson: keypointsJson,
          imagePath: _imageFile!.path,
          timestamp: DateTime.now(),
        );
        await DBService().insertEntry(entry);
        setState(() {
          _keypointsJson = keypointsJson;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved locally.')));
      } else {
        LoggerService.logError('Failed to get keypoints from backend');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backend error.')));
      }
    } catch (e, st) {
      LoggerService.logError('Error analyzing image', e, st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error analyzing image.')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture or Pick Image')),
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
            if (_imageFile != null) Image.file(_imageFile!, height: 200),
            const SizedBox(height: 24),
            if (_imageFile != null && !_loading)
              ElevatedButton(
                onPressed: _analyzeAndSave,
                child: const Text('Analyze & Save'),
              ),
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
