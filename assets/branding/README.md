# Wishpr branding assets (beta → production)

Use this folder for **final** marketing and launcher artwork so it stays separate from generated platform trees.

## App / launcher icon

1. Export a **1024×1024** PNG (no transparency for the full square, or follow store guidelines).
2. Save as `app_icon_1024.png` in this folder.
3. Point `flutter_launcher_icons.yaml` at `assets/branding/app_icon_1024.png`.
4. Run:

   ```bash
   dart run flutter_launcher_icons
   ```

5. Commit the updated `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset`, and `web/icons` outputs.

## Native Android splash (optional)

To show a centered logo before Flutter loads, add a bitmap to `android/app/src/main/res/drawable/launch_background.xml` (see comment in that file) and keep background color `#0D0614` to match `WishprColors.background`.

## iOS

Replace `LaunchScreen.storyboard` artwork or `LaunchImage` in `Assets.xcassets` when you have a static splash; the storyboard background is already set to the Wishpr dark purple.
