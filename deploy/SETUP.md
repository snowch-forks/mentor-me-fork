# MentorMe - Secure GCP Web App Setup

Deploy MentorMe as a private web app on Google Cloud, accessible only to you and your wife via your Google accounts.

## Architecture

```
Browser (you/wife)
  → Google Identity-Aware Proxy (IAP)   ← only your 2 Google accounts allowed
    → Cloud Run                          ← serverless, ~$0-5/month
      → nginx (Flutter web app)
      → Node.js proxy (Claude API)       ← API key stored server-side
```

**Security layers:**
- **IAP** - Google login required; only allowlisted accounts get through
- **Server-side API key** - Claude key in Secret Manager, never in the browser
- **HTTPS** - automatic via Cloud Run
- **`--no-allow-unauthenticated`** - Cloud Run rejects all unauthenticated requests

## Cost Estimate

For 2 users with light usage:
- **Cloud Run**: ~$0-2/month (scales to zero when idle, pay per request)
- **Cloud Build**: Free tier covers ~120 build-minutes/day
- **Secret Manager**: Free for 6 active secret versions
- **IAP**: Free
- **Total: ~$0-5/month**

---

## One-Time Setup (30-45 minutes)

### Step 1: Create a GCP Project

1. Go to https://console.cloud.google.com
2. Click **Select a project** → **New Project**
3. Name it something like `mentorme-app`
4. Note the **Project ID** (e.g., `mentorme-app-12345`)
5. Enable billing: **Billing** → **Link a billing account**

### Step 2: Install gcloud CLI

```bash
# macOS
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash

# Then authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Step 3: Store Your Claude API Key

```bash
# Store your Anthropic API key in Secret Manager
echo -n 'sk-ant-api03-YOUR-KEY-HERE' | \
  gcloud secrets create claude-api-key \
    --data-file=- \
    --project=YOUR_PROJECT_ID
```

To update the key later:
```bash
echo -n 'sk-ant-api03-NEW-KEY' | \
  gcloud secrets versions add claude-api-key --data-file=-
```

### Step 4: Deploy

```bash
# From the repo root
chmod +x deploy/deploy.sh
./deploy/deploy.sh --project YOUR_PROJECT_ID
```

This will:
1. Enable required GCP APIs
2. Build the container via Cloud Build (~5-10 min first time)
3. Deploy to Cloud Run with the secret mounted
4. Block all unauthenticated access

Note the **Service URL** printed at the end (e.g., `https://mentorme-abc123-uc.a.run.app`).

### Step 5: Configure IAP (Identity-Aware Proxy)

This is the key security step - it restricts access to your Google accounts only.

#### 5a: Configure OAuth Consent Screen

1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. Select **External** (or **Internal** if using Google Workspace)
3. Fill in:
   - App name: `MentorMe`
   - User support email: your email
   - Developer contact: your email
4. Click **Save and Continue** through scopes (no changes needed)
5. Add **Test users**: your email and your wife's email
6. Click **Save**

#### 5b: Enable IAP on Cloud Run

1. Go to: https://console.cloud.google.com/security/iap
2. If prompted, click **Configure Consent Screen** (should already be done)
3. Find your **mentorme** Cloud Run service in the list
4. Toggle the **IAP** switch to **ON** for the service
5. Click **Turn On** in the confirmation dialog

#### 5c: Add Authorized Users

1. Still on the IAP page, click the checkbox next to **mentorme**
2. Click **Add Principal** in the right panel
3. Add your email → Role: **IAP-secured Web App User**
4. Click **Add Another** → Add your wife's email → Same role
5. Click **Save**

#### 5d: Create OAuth Credentials (if needed)

If IAP asks for OAuth credentials:

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click **Create Credentials** → **OAuth client ID**
3. Type: **Web application**
4. Name: `MentorMe IAP`
5. Authorized redirect URI: `https://iap.googleapis.com/v1/oauth/clientIds/CLIENT_ID:handleRedirect`
   (IAP usually auto-configures this)
6. Copy the **Client ID** and **Client Secret** back to IAP settings

### Step 6: Test Access

1. Open the Cloud Run service URL in your browser
2. You should see a Google login screen
3. Log in with your Google account → app loads
4. Test with your wife's account too
5. Try an incognito window with a different account → should be blocked

---

## Ongoing Operations

### Redeploy After Code Changes

```bash
./deploy/deploy.sh --project YOUR_PROJECT_ID
```

### Update Claude API Key

```bash
echo -n 'sk-ant-api03-NEW-KEY' | \
  gcloud secrets versions add claude-api-key --data-file=-

# Redeploy to pick up new secret version
gcloud run services update mentorme \
  --region us-central1 \
  --set-secrets "CLAUDE_API_KEY=claude-api-key:latest"
```

### View Logs

```bash
gcloud run services logs read mentorme \
  --region us-central1 \
  --project YOUR_PROJECT_ID \
  --limit 50
```

### Delete Everything (cleanup)

```bash
# Delete Cloud Run service
gcloud run services delete mentorme --region us-central1

# Delete container images
gcloud container images delete gcr.io/YOUR_PROJECT_ID/mentorme --force-delete-tags

# Delete secret
gcloud secrets delete claude-api-key

# (Optional) Delete entire project
gcloud projects delete YOUR_PROJECT_ID
```

---

## Troubleshooting

### "Error: Redirect" after login
IAP OAuth consent screen may need your email added as a **test user** (Step 5a).

### "403 Forbidden" after Google login
Your account isn't in the IAP allowlist. Redo Step 5c.

### App loads but AI features don't work
1. Check the secret is mounted: `gcloud run services describe mentorme --format=yaml | grep secret`
2. Check logs: `gcloud run services logs read mentorme --limit 20`
3. Look for `FATAL: CLAUDE_API_KEY environment variable not set`

### Build fails
- Check Cloud Build logs: https://console.cloud.google.com/cloud-build/builds
- Common issue: Flutter dependencies failing → retry usually fixes transient network issues

### "Service is unavailable" (cold start)
Cloud Run scales to zero. First request after idle period takes 5-15 seconds to cold start. This is normal and saves cost.

---

## Security Notes

- **API key**: Stored in GCP Secret Manager, injected as environment variable at runtime. Never in source code, never sent to browser.
- **Authentication**: Google IAP handles all auth. No passwords, no custom auth code.
- **HTTPS**: Automatic TLS termination by Cloud Run.
- **Network**: `--no-allow-unauthenticated` means even with the URL, unauthenticated requests are rejected at the infrastructure level.
- **Rate limiting**: The proxy has simple per-IP rate limiting (30 req/min) as a safety net.
- **No public data**: All user data stays in-browser (SharedPreferences/localStorage). Nothing is stored server-side except the API key.
