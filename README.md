# Form Photo Resizer

Resizes a photo, signature or scanned document to the pixel size and KB limits of an Indian exam or government form. Everything runs on your device. Nothing is uploaded, there is no account, and the release Android build has no internet permission.

For students and job seekers who are told "photo must be 20 to 50 KB, 200 x 230 px" five minutes before the last date.

## What it does

- You choose an image, type the limits (or pick a starting point), and press Resize.
- If a width and height are set, the image is centre-cropped to that shape and resized to exactly that many pixels.
- If they are left empty, the pixel size is kept and only shrunk when the file is too big.
- The JPEG quality is searched (binary search) for the highest quality that stays under your maximum.
- Transparent PNGs are painted on white, since JPEG has no transparency.
- Phone photos are rotated upright using their EXIF orientation.

## What it does not do

- **It does not know the official limits.** The starting points (IBPS, SSC, UPSC) are typical figures collected from third-party guides in November 2026. Those guides disagree with each other on pixel sizes, and portals change the numbers between notifications. Read the limits from your own notification and edit the boxes. SSC and UPSC starting points have no pixel size for that reason.
- It does not edit the picture: no background removal, no brightening, no face check. A photo that the portal rejects for how it looks will still be rejected.
- It does not make PDFs. It outputs JPEG only.

## How file size is measured

Portals do not say whether 1 KB is 1000 or 1024 bytes. The output is at most `max x 1000` bytes and at least `min x 1024` bytes, so it passes under either definition. The result card shows both KB and KiB.

When a picture is so simple that even the best quality is smaller than your minimum (a flat signature, for example), zero bytes are appended after the JPEG end marker until the minimum is reached. Image decoders ignore them and the picture is unchanged. The app tells you when it did this.

If your limits cannot both be met (for example a 1000 x 1000 px image under 1 KB), the app says so instead of silently breaking the pixel size.

## Run it

```bash
flutter pub get
flutter run -d chrome        # web
flutter run                  # Android device or emulator
flutter test
```

Web build served from GitHub Pages: https://chandrachaan.github.io/form-photo-resizer/

Android: download the APK from the [Releases](https://github.com/ChandraChaan/form-photo-resizer/releases) page. The APK is signed with the debug key, so Android will ask you to allow installing from outside the Play Store.

## Project layout

| Path | What it holds |
|---|---|
| `lib/src/resizer.dart` | The resize engine: crop, resize, quality search, padding. Pure Dart. |
| `lib/src/preset.dart` | The `Preset` model and the starting-point list. |
| `lib/src/home_page.dart` | The single screen. |
| `test/resizer_test.dart` | Engine tests with synthetic images. |

## Adding or correcting a starting point

Edit `builtInPresets` in `lib/src/preset.dart`. Please link the official notification in the pull request. A figure that only appears on a coaching or tool site is not enough.

## License

MIT. Copyright (c) 2026 Chandra ObulaReddy.
