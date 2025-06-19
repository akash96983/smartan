import 'package:flutter/material.dart';
import '../models/keypoint_entry.dart';
import '../services/db_service.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_service.dart';
import '../services/logger_service.dart';
import '../widgets/image_thumbnail.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<KeypointEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _entriesFuture = DBService().fetchAllEntries();
    });
  }

  Future<void> _syncEntry(KeypointEntry entry) async {
    try {
      final imageUrl = await CloudinaryService.uploadImage(
        File(entry.imagePath),
      );
      if (imageUrl != null) {
        await FirebaseService.syncKeypointEntry(entry, imageUrl);
        if (entry.id != null) {
          await DBService().updateSyncStatus(entry.id!, true);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Synced online!')));
        _refresh();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cloud sync failed.')));
      }
    } catch (e, st) {
      LoggerService.logError('Sync error', e, st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error syncing online.')));
    }
  }

  Future<void> _deleteEntry(KeypointEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && entry.id != null) {
      await DBService().deleteEntry(entry.id!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry deleted.')));
      _refresh();
    }
  }

  void _showJsonDialog(String json) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keypoints JSON'),
        content: SingleChildScrollView(child: SelectableText(json)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Container(
        color: const Color(0xFFF7F9FB),
        child: FutureBuilder<List<KeypointEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No entries found.'));
            }
            final entries = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ImageThumbnail(
                                imagePath: entry.imagePath,
                                size: 80,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Timestamp:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    entry.timestamp
                                        .toLocal()
                                        .toString()
                                        .split(".")
                                        .first,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    entry.keypointsJson.length > 60
                                        ? entry.keypointsJson.substring(0, 60) +
                                              '...'
                                        : entry.keypointsJson,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              label: const Text(
                                'Details',
                                style: TextStyle(color: Colors.blue),
                              ),
                              onPressed: () =>
                                  _showJsonDialog(entry.keypointsJson),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!entry.isSynced)
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.cloud_upload,
                                  color: Colors.green,
                                ),
                                label: const Text(
                                  'Sync Online',
                                  style: TextStyle(color: Colors.green),
                                ),
                                onPressed: () => _syncEntry(entry),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            else
                              const Center(
                                child: Chip(
                                  label: Text(
                                    'Synced',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  avatar: Icon(
                                    Icons.cloud_done,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                  backgroundColor: Color(0xFFE8F5E9),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _deleteEntry(entry),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
