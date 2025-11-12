# APK Download & Release Guide

This guide explains how to create downloadable APK releases for MentorMe using GitHub Actions.

## 📦 Creating a New Release

### Method 1: Push a Version Tag (Recommended)

This is the easiest way to create a release. Simply push a version tag:

```bash
# Create a version tag (e.g., v1.0.0)
git tag v1.0.0

# Push the tag to GitHub
git push origin v1.0.0
```

**What happens next:**
1. GitHub Actions automatically detects the tag
2. Builds the release APK and AAB
3. Creates a GitHub Release with auto-generated release notes
4. Attaches the APK and AAB files for download

### Method 2: Manual Trigger

You can also manually trigger a release from GitHub:

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Android Release** workflow
4. Click **Run workflow** button
5. Enter the version (e.g., `v1.0.0`)
6. Click **Run workflow**

## 📥 Downloading APKs

### For End Users

1. Go to your GitHub repository
2. Click on **Releases** (right sidebar)
3. Find the version you want to download
4. Under **Assets**, click on `mentor-me-vX.X.X.apk`
5. The APK will download directly

**Direct link format:**
```
https://github.com/YOUR_USERNAME/mentor-me/releases/latest/download/mentor-me-vX.X.X.apk
```

### For Developers (from Actions artifacts)

If you need APKs from any commit (not just releases):

1. Go to **Actions** tab
2. Click on a completed workflow run
3. Scroll to **Artifacts** section
4. Download `debug-apks` or `release-apks`

## 🔢 Version Numbering

Follow semantic versioning: `vMAJOR.MINOR.PATCH`

- **Major (v1.0.0 → v2.0.0):** Breaking changes, major new features
- **Minor (v1.0.0 → v1.1.0):** New features, backwards compatible
- **Patch (v1.0.0 → v1.0.1):** Bug fixes, small improvements

**Examples:**
```bash
git tag v1.0.0     # First release
git tag v1.1.0     # Added new feature
git tag v1.1.1     # Bug fix
git tag v2.0.0     # Major update
```

## 📝 Release Notes

Release notes are automatically generated from git commits between tags.

**To improve release notes:**
- Write clear, descriptive commit messages
- Use conventional commits format:
  ```
  feat: Add guided journaling feature
  fix: Resolve notification timing issue
  docs: Update installation instructions
  ```

## 🔐 Signing APKs (Optional)

By default, release APKs are signed with a debug key. For production distribution:

### 1. Generate a signing key

```bash
keytool -genkey -v -keystore mentor-me-release.keystore \
  -alias mentor-me -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Add GitHub Secrets

Go to **Settings → Secrets → Actions** and add:

- `ANDROID_KEYSTORE_BASE64` - Base64-encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password

**Encode keystore to base64:**
```bash
base64 -i mentor-me-release.keystore | pbcopy  # macOS
base64 -w 0 mentor-me-release.keystore          # Linux
```

### 3. Update workflow

The workflow will automatically use signing keys if secrets are configured.

## 📱 Installation Instructions for Users

Include these instructions in your release notes or README:

### Android APK Installation

#### System Requirements

**⚠️ IMPORTANT:** Check these requirements before downloading:

- **Android 12.0 (API 31) or higher** - Required
- ARMv8 64-bit processor (ARM64 or ARM)
- 4GB+ RAM (6GB+ recommended for Local AI)
- 2GB free storage (if using Local AI features)

**To check your Android version:**
1. Open **Settings**
2. Go to **About Phone**
3. Look for **Android version**
4. **If it says Android 11 or lower, this APK will NOT install**

> **Why Android 12+?** The app uses Google's LiteRT LLM library for on-device AI features, which requires Android 12 as the minimum SDK. This is a hard requirement and cannot be bypassed.

#### Installation Steps

1. **Check Android Version** (see requirements above)

2. **Download APK:**
   - Go to [Releases](https://github.com/YOUR_USERNAME/mentor-me/releases)
   - Download the latest `mentor-me-vX.X.X.apk`
   - (Optional) Download `.sha256` file to verify integrity

3. **Enable installation from unknown sources:**
   - **Android 12-14:**
     - Settings → Apps → Special app access → Install unknown apps
     - Select your browser (Chrome, Firefox, etc.)
     - Toggle "Allow from this source"
   - **Android 11 and below:**
     - Settings → Security → Unknown sources (toggle on)
     - Note: This APK won't install on Android 11 anyway due to minSdk requirement

4. **Install:**
   - Open the downloaded APK file from your Downloads folder
   - Tap **Install**
   - If Play Protect shows a warning, tap **Install anyway**
   - Wait for installation to complete
   - Open the app and enjoy! 🎉

### First-Time Setup

After installation:

1. **Set up AI provider:**
   - Choose **Cloud AI** (requires Anthropic API key) or **Local AI** (downloads 550MB model)
   - For Cloud AI: Get API key from [console.anthropic.com](https://console.anthropic.com/)

2. **Create your first goal:**
   - Tap the **+** button on the Goals screen
   - Enter your goal title and details

3. **Explore features:**
   - **Journal:** Quick notes and guided journaling
   - **Habits:** Track daily habits with streak tracking
   - **Chat:** Conversational AI mentor
   - **Pulse:** Track wellness metrics (mood, energy, focus)

## 🔄 CI/CD Workflows

This repository has three workflows:

| Workflow | Trigger | Purpose | Artifacts |
|----------|---------|---------|-----------|
| **android-build.yml** | Push to any branch | Continuous testing | Debug + Release APKs (30-90 days) |
| **android-release.yml** | Version tag push | Create public release | Permanent GitHub Release |
| - | Pull requests | Validation | None |

## 🐛 Troubleshooting

### Common Installation Issues

#### "App not installed" or "Package appears to be invalid"

**Most Common Cause:** Your Android version is too old.

**Solution:**
1. Check your Android version:
   - Settings → About Phone → Android version
   - **Required: Android 12.0 or higher**

2. If you have Android 11 or lower:
   - This APK will NOT work on your device
   - The app requires Android 12+ due to LiteRT LLM library requirements
   - Consider:
     - Upgrading your device to Android 12+ (if available)
     - Using a different device with Android 12+
     - Waiting for a potential Android 11-compatible version (would require removing local AI features)

**Other Possible Causes:**

- **Corrupted download:**
  - Re-download the APK
  - Verify checksum matches the `.sha256` file
  - Try downloading on a different network

- **Architecture mismatch (rare):**
  - This app is built for ARM and ARM64 processors
  - Older x86 Android devices (rare) won't work
  - Check device specs to confirm ARM processor

- **Insufficient storage:**
  - Ensure at least 500MB free space for installation
  - Check Settings → Storage

- **Previous version installed with different signature:**
  - Uninstall any previous version first
  - Then install the new APK

#### "Installation blocked" or "Install blocked by Play Protect"

**Problem:** Android security is blocking installation

**Solution:**
1. For "unknown sources" block:
   - Enable "Install from unknown sources" (see installation steps above)

2. For Play Protect warning:
   - Tap "More details" or "Install anyway"
   - The APK is safe but not from Play Store, so Play Protect shows a warning
   - This is normal for sideloaded APKs

#### APK Downloads But Won't Open

**Problem:** APK file downloads but doesn't trigger installer

**Solution:**
- Open your **Files** or **Downloads** app
- Navigate to Downloads folder
- Tap the APK file directly
- Make sure you downloaded the `.apk` file, not the `.sha256` or `.md5` file

---

### Developer/Maintainer Issues

### "Failed to create release"

**Problem:** Workflow fails with permission error

**Solution:** Enable workflow write permissions:
1. Go to **Settings → Actions → General**
2. Under **Workflow permissions**, select **Read and write permissions**
3. Click **Save**

### "Tag already exists"

**Problem:** You're trying to create a tag that already exists

**Solution:**
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push --delete origin v1.0.0

# Create new tag
git tag v1.0.0
git push origin v1.0.0
```

### "APK not found in release"

**Problem:** Release created but APK missing

**Solution:**
- Check the workflow run logs in **Actions** tab
- Look for build errors in the "Build release APK" step
- Verify Flutter version compatibility

## 📊 Download Statistics

GitHub provides download statistics for releases:

1. Go to **Releases**
2. Each release shows download count for each asset
3. Use GitHub API for detailed analytics:
   ```bash
   curl -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/YOUR_USERNAME/mentor-me/releases
   ```

## 🚀 Best Practices

1. **Test before tagging:**
   - Merge all changes to main/master
   - Wait for CI/CD to pass
   - Test the APK from artifacts
   - Then create the release tag

2. **Meaningful versions:**
   - Don't skip versions
   - Use pre-release tags for betas: `v1.0.0-beta.1`
   - Keep CHANGELOG.md updated

3. **Communication:**
   - Announce new releases to users
   - Include upgrade instructions
   - Highlight breaking changes

4. **Security:**
   - Never commit keystore files
   - Rotate signing keys if compromised
   - Use GitHub Secrets for sensitive data

## 📚 Additional Resources

- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Semantic Versioning](https://semver.org/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

**Quick Reference:**

```bash
# Create and push a release
git tag v1.0.0
git push origin v1.0.0

# View all tags
git tag -l

# Delete a tag
git tag -d v1.0.0
git push --delete origin v1.0.0
```
