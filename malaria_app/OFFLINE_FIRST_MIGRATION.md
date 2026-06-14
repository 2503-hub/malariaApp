# Offline-First Malaria Detection Migration

This app now supports fully on-device malaria detection through TensorFlow Lite.

## What changed

- Image analysis runs locally in Flutter through `OnDeviceMalariaService`.
- Prediction history now stores the detection mode in SQLite.
- Batch analysis uses the same local inference path.
- The backend is still available for chat and other existing server features.

## Required assets

- `assets/models/malaria_classifier.tflite`
- `assets/models/labels.txt`

## Regenerate the TFLite model

Run this from the repository root:

```powershell
& .\tf-env\Scripts\python.exe .\backend\scripts\convert_malaria_model_to_tflite.py
```

This converts `malaria_model.keras` into the Flutter asset at:

- `malaria_app/assets/models/malaria_classifier.tflite`

## Refresh Flutter dependencies

After changing `pubspec.yaml`, run:

```powershell
cd malaria_app
flutter pub get
```

## Build or run on Android

1. Ensure the model asset exists in `malaria_app/assets/models/`.
2. Run `flutter pub get`.
3. Make sure the Android app is built with `minSdk 26` or higher.
4. Launch the app on an Android device or emulator.
5. Select an image and confirm the result screen shows `Offline Detection`.

## Notes

- The model expects `64 x 64 x 3` RGB input.
- The Keras model already contains a `Rescaling` layer, so the on-device pipeline feeds raw pixel values.
- Existing pending-sync records from older versions remain supported and will still be replayed by the app.
