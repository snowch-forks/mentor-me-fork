# Android CI/CD Documentation

This directory contains GitHub Actions workflows for automated Android builds.

## Workflows

### `android-build.yml`

**Trigger Events:**
- Push to `main`, `master`, `develop`, or any `claude/**` branch
- Pull requests to `main`, `master`, or `develop`
- Manual workflow dispatch

**Jobs:**

1. **build** - Builds debug and release APKs
   - Runs Flutter analyzer
   - Runs Flutter tests (non-blocking)
   - Builds split APKs per ABI (arm64-v8a, armeabi-v7a, x86_64)
   - Uploads artifacts with 30-day (debug) and 90-day (release) retention

2. **build-appbundle** - Builds Android App Bundle (AAB) for Play Store
   - Only runs on `main`/`master` branches or manual triggers
   - Produces optimized AAB for Google Play Store distribution
   - Uploads artifact with 90-day retention

3. **build-info** - Generates build metadata
   - Creates build summary with commit info
   - Displays recent commits

## Artifacts

After successful builds, the following artifacts are available:

| Artifact | File Pattern | Retention | Purpose |
|----------|--------------|-----------|---------|
| `debug-apks` | `*-debug.apk` | 30 days | Testing and development |
| `release-apks` | `*-release.apk` | 90 days | Production releases (unsigned or debug-signed) |
| `release-aab` | `app-release.aab` | 90 days | Google Play Store upload |

### Downloading Artifacts

1. Go to the **Actions** tab in your GitHub repository
2. Click on the workflow run
3. Scroll to the **Artifacts** section at the bottom
4. Download the APK or AAB files

## Release Signing Configuration

### Current State

The workflow currently builds release APKs/AABs using:
- **Debug signing** (if `key.properties` doesn't exist in the repository)
- **Release signing** (if `key.properties` is present in the repository)

⚠️ **Important:** Debug-signed builds cannot be published to the Google Play Store.

### Setting Up Release Signing for CI/CD

For production releases, you need to configure GitHub Secrets for signing:

#### Step 1: Generate a Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore mentor-me-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mentor-me-key
```

This creates a keystore file `mentor-me-release.jks`. **Keep this file secure!**

#### Step 2: Encode Keystore as Base64

```bash
base64 -i mentor-me-release.jks | pbcopy  # macOS
base64 mentor-me-release.jks | xclip -selection clipboard  # Linux
certutil -encode mentor-me-release.jks keystore-base64.txt  # Windows
```

#### Step 3: Configure GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file | `MIIKXwIBAz...` (long string) |
| `ANDROID_KEY_ALIAS` | Keystore key alias | `mentor-me-key` |
| `ANDROID_KEY_PASSWORD` | Key password | `your-key-password` |
| `ANDROID_STORE_PASSWORD` | Keystore password | `your-store-password` |

#### Step 4: Update Workflow to Use Secrets

Create a new workflow file `.github/workflows/android-release.yml`:

```yaml
name: Android Release Build

on:
  push:
    tags:
      - 'v*.*.*'  # Trigger on version tags (e.g., v1.0.0)
  workflow_dispatch:

jobs:
  release-build:
    name: Build Signed Release
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.1'
          channel: 'stable'
          cache: true

      - name: Get Flutter dependencies
        run: flutter pub get

      - name: Decode keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > android/app/mentor-me-release.jks

      - name: Create key.properties
        env:
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
        run: |
          cat > android/key.properties <<EOF
          storeFile=mentor-me-release.jks
          storePassword=$STORE_PASSWORD
          keyAlias=$KEY_ALIAS
          keyPassword=$KEY_PASSWORD
          EOF

      - name: Build signed APK
        run: flutter build apk --release

      - name: Build signed App Bundle
        run: flutter build appbundle --release

      - name: Upload signed APK
        uses: actions/upload-artifact@v4
        with:
          name: signed-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

      - name: Upload signed AAB
        uses: actions/upload-artifact@v4
        with:
          name: signed-release-aab
          path: build/app/outputs/bundle/release/app-release.aab

      - name: Clean up keystore
        if: always()
        run: |
          rm -f android/app/mentor-me-release.jks
          rm -f android/key.properties
```

#### Step 5: Tag a Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the signed release build automatically.

## Build Configuration Details

### Flutter Version
- **Version:** 3.27.1 (stable)
- **Channel:** stable
- Configured in workflow for consistency

### Java Version
- **Version:** 17 (Temurin distribution)
- Required for Android Gradle Plugin and Kotlin

### Android Configuration
- **Min SDK:** 31 (Android 12) - Required for LiteRT LLM
- **Target SDK:** Auto-detected from Flutter SDK
- **Compile SDK:** Auto-detected from Flutter SDK
- **AGP Version:** 8.9.1
- **Kotlin Version:** 2.1.0

### Build Optimization
- **Code Shrinking:** Enabled (R8)
- **Resource Shrinking:** Enabled
- **ProGuard:** Configured (`proguard-rules.pro`)
- **Split APKs:** Per-ABI for smaller downloads

## Troubleshooting

### Build Failures

**Issue:** `Could not find flutter.properties`
- **Solution:** Ensure Flutter is properly set up in the workflow. This is handled automatically by `subosito/flutter-action`.

**Issue:** `Execution failed for task ':app:lintVitalRelease'`
- **Solution:** Add `lintOptions { checkReleaseBuilds false }` to `android/app/build.gradle.kts` or fix lint errors.

**Issue:** `AAPT: error: resource android:attr/lStar not found`
- **Solution:** Ensure `compileSdk` is 31 or higher.

**Issue:** Signing errors
- **Solution:** Verify all GitHub Secrets are correctly set and the keystore password matches.

### Testing Locally

To test the build process locally (without CI):

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Build release APK (requires key.properties for signing)
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## Best Practices

1. **Branch Protection**
   - Require status checks to pass before merging
   - Enable branch protection on `main`/`master`

2. **Artifact Management**
   - Debug APKs: 30-day retention (short-lived testing)
   - Release APKs/AABs: 90-day retention (production archives)

3. **Semantic Versioning**
   - Use version tags (`v1.0.0`, `v1.0.1`, etc.)
   - Trigger signed releases only on version tags

4. **Security**
   - Never commit keystore files or `key.properties`
   - Use GitHub Secrets for sensitive data
   - Rotate signing keys periodically (with caution)

5. **Testing**
   - Add more Flutter tests to improve CI validation
   - Consider adding integration tests

## Monitoring Builds

### GitHub Actions UI
- View all workflow runs: **Actions** tab
- Check build logs for errors
- Download artifacts after successful builds

### Status Badges

Add to `README.md`:

```markdown
![Android Build](https://github.com/YOUR_USERNAME/mentor-me/workflows/Android%20Build%20CI%2FCD/badge.svg)
```

Replace `YOUR_USERNAME` with your GitHub username.

## Advanced Configuration

### Matrix Builds

To build for multiple Flutter versions or channels:

```yaml
strategy:
  matrix:
    flutter-version: ['3.24.0', '3.27.1']
    channel: ['stable', 'beta']
```

### Conditional Signing

The current workflow uses conditional signing:
- If `key.properties` exists → use release signing
- If not → fallback to debug signing

This allows flexibility for:
- Development branches (debug signing)
- Main branch (release signing with GitHub Secrets)

## Support

For issues with:
- **Flutter build errors:** Check [Flutter documentation](https://docs.flutter.dev/)
- **GitHub Actions:** Check [GitHub Actions documentation](https://docs.github.com/en/actions)
- **Android signing:** Check [Android documentation](https://developer.android.com/studio/publish/app-signing)

---

**Last Updated:** 2025-11-12
