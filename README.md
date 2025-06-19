# Smartan: MediaPipe Pose Analysis Flutter App

## Overview
A production-ready Flutter app for capturing images, extracting body keypoints using a backend (Node.js with MediaPipe), storing results locally (SQLite), and syncing images/keypoints to Firebase (Firestore & Storage) and Cloudinary.

## Features
- Capture or select images
- Send images to backend for keypoints extraction
- Store keypoints, timestamp, and image path in SQLite
- Upload images to Cloudinary
- Sync keypoints and image URLs to Firestore
- View history of all entries with thumbnails and details
- Robust error handling and logging (local only)

## Tech Stack
- Flutter (Stable)
- SQLite (sqflite)
- Firebase Firestore & Storage
- Cloudinary (for image storage)
- Node.js backend (for MediaPipe keypoints extraction)

## Folder Structure
```
lib/
  main.dart
  models/
    keypoint_entry.dart
  screens/
    camera_screen.dart
    history_screen.dart
    details_screen.dart
  services/
    api_service.dart
    cloudinary_service.dart
    firebase_service.dart
    db_service.dart
    logger_service.dart
  widgets/
    image_thumbnail.dart
```

## Setup Instructions
1. **Flutter**: Install dependencies with `flutter pub get`.
2. **Firebase**: Add your `google-services.json` to `android/app/` and configure Firestore/Storage.
3. **Cloudinary**: Use provided credentials for image upload.
4. **Backend**: Set the backend endpoint in `api_service.dart` when available.

## Error Handling
- All errors (network, DB, logic) are logged locally using `logger_service.dart`.
- No error logs are sent to Firestore.

## UI/UX
- Simple, clean Material UI.

## To Do
- [ ] Implement all features as per requirements
- [ ] Polish and test for production
