import 'dart:convert';

class KeypointEntry {
  final int? id; // For SQLite primary key
  final String keypointsJson;
  final String imagePath; // Local path or Cloudinary URL
  final DateTime timestamp;
  final bool isSynced; // Whether synced to Firestore/Cloudinary

  KeypointEntry({
    this.id,
    required this.keypointsJson,
    required this.imagePath,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keypointsJson': keypointsJson,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory KeypointEntry.fromMap(Map<String, dynamic> map) {
    return KeypointEntry(
      id: map['id'] as int?,
      keypointsJson: map['keypointsJson'] as String,
      imagePath: map['imagePath'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'keypointsJson': keypointsJson,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static KeypointEntry fromFirestore(Map<String, dynamic> map) {
    return KeypointEntry(
      keypointsJson: map['keypointsJson'] as String,
      imagePath: map['imagePath'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: true,
    );
  }
}
