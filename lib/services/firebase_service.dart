import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/keypoint_entry.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadImageToStorage(File imageFile) async {
    try {
      final ref = _storage.ref().child(
        'images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}',
      );
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  static Future<void> syncKeypointEntry(
    KeypointEntry entry,
    String imageUrl,
  ) async {
    await _firestore.collection('keypoints').add({
      'keypointsJson': entry.keypointsJson,
      'imagePath': imageUrl,
      'timestamp': entry.timestamp.toIso8601String(),
    });
  }
}
