# Smartan: Keypoints Detection Flutter App

## Overview
Smartan is a Flutter app for detecting human pose keypoints in images using Google ML Kit (on-device, no backend required). Results are saved locally and can be synced to the cloud. The UI is modern, simple, and production-ready.

## Features
- **Local keypoint detection**: Uses Google ML Kit for fast, private, on-device pose detection.
- **Save locally**: Every detection (image, keypoints JSON, timestamp) is saved to SQLite with one tap.
- **History**: View all runs with thumbnails, JSON preview, and details.
- **Sync to cloud**: Sync any entry to Cloudinary (image) and Firestore (keypoints+image URL) from the history page.
- **Delete**: Remove any entry from local storage.
- **Overlay always matches image**: Keypoints and skeleton are always perfectly aligned and never exceed the image bounds.
- **Modern, simple UI**: Clean navigation, fixed Save button, and responsive design.

## Workflow
1. **Detect**: Capture or select an image, detect keypoints locally.
2. **Save locally**: Tap the Save button (fixed at the bottom) to store the result in SQLite.
3. **View in History**: See all saved runs, with options to view details, sync, or delete.
4. **Sync online**: Sync to Cloudinary/Firestore only when you choose.

## Tech Stack
- Flutter (Stable)
- Google ML Kit (Pose Detection)
- SQLite (sqflite)
- Cloudinary (image sync)
- Firebase Firestore (keypoints sync)

## Setup Instructions
1. **Clone the repo** and run `flutter pub get`.
2. **Add your `google-services.json`** to `android/app/` for Firebase.
3. **Configure Cloudinary credentials** in `cloudinary_service.dart`.
4. **Run the app**: `flutter run`

## UI/UX Highlights
- Home: Gallery/Camera buttons, image preview with perfectly aligned overlay, fixed Save button.
- History: Card-based list, details, sync, and delete actions.
- All overlays are clipped to the image, never exceeding bounds.

## Error Handling
- All errors are logged locally.
- No error logs are sent to Firestore.

## License
MIT
