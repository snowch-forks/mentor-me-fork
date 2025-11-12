# Proxy Server Setup Guide
## Enable AI Features on Flutter Web

This guide will help you set up a proxy server so AI features work on web.

---

## Why We Need This

**Problem:** Browsers block direct API calls to external domains (CORS policy)

**Solution:** Local proxy server that:
- Receives requests from Flutter web app
- Forwards them to Claude API
- Adds CORS headers so browser allows it

```
Flutter Web → Proxy Server (localhost:3000) → Claude API
            ✅ Allowed                        ✅ Allowed
```

---

## Step-by-Step Setup

### 1. Create Proxy Server Directory

```bash
# In your project root
cd ..  # Go up from Flutter project
mkdir claude-proxy-server
cd claude-proxy-server
```

### 2. Initialize Node.js Project

```bash
npm init -y
```

### 3. Install Dependencies

```bash
npm install express cors node-fetch@3
npm install --save-dev nodemon
```

### 4. Create Server File

Create `server.js` (copy from "complete_proxy_server" artifact above)

### 5. Update package.json

Replace the generated `package.json` with the one from "proxy_package_json" artifact above.

**Key change:** Add `"type": "module"` to use ES6 imports.

### 6. Start the Proxy Server

```bash
npm start
```

You should see:
```
╔════════════════════════════════════════╗
║  Claude API Proxy Server               ║
║  Running on http://localhost:3000      ║
╚════════════════════════════════════════╝
```

**Keep this terminal running!**

---

## Update Flutter App

### 1. Replace AI Service

Replace `lib/services/ai_service.dart` with the "proxy_aware_ai_service" artifact.

**Key change:**
```dart
// Uses proxy on web, direct API on mobile
final url = kIsWeb ? _proxyUrl : _apiUrl;
```

### 2. Update Other Services

The goal decomposition and blocker detection services will automatically work through the updated AIService.

---

## Testing

### Terminal 1: Start Proxy Server
```bash
cd claude-proxy-server
npm start
```

### Terminal 2: Run Flutter Web
```bash
cd ai_mentor_coach  # Your Flutter project
flutter run -d chrome
```

### Test AI Features

1. **Settings** → Enter API key → Save
2. **Goals** → Add Goal → Fill details
3. **Click "Get AI Milestone Suggestions"**
4. ✅ Should work! Check proxy server terminal for logs

---

## Project Structure

After setup, your structure should look like:

```
your-workspace/
├── ai_mentor_coach/          # Flutter project
│   ├── lib/
│   │   ├── services/
│   │   │   ├── ai_service.dart    ← Updated
│   │   │   ├── goal_decomposition_service.dart
│   │   │   └── blocker_detection_service.dart
│   │   └── ...
│   └── pubspec.yaml
│
└── claude-proxy-server/      # NEW: Proxy server
    ├── server.js
    ├── package.json
    └── node_modules/
```

---

## Troubleshooting

### Error: "Cannot connect to proxy server"

**Check proxy is running:**
```bash
curl http://localhost:3000
# Should return: {"status":"ok",...}
```

**If not running:**
```bash
cd claude-proxy-server
npm start
```

### Error: "npm: command not found"

**Install Node.js:**
- Download from: https://nodejs.org
- Install LTS version
- Restart terminal

### Error: Port 3000 already in use

**Option 1:** Kill the process using port 3000
```bash
# Mac/Linux
lsof -ti:3000 | xargs kill -9

# Windows
netstat -ano | findstr :3000
taskkill /PID <pid> /F
```

**Option 2:** Use different port
```javascript
// In server.js
const PORT = process.env.PORT || 3001;  // Changed to 3001
```

Then update Flutter:
```dart
// In ai_service.dart
static const String _proxyUrl = 'http://localhost:3001/api/claude/messages';
```

### Error: "Failed to fetch"

1. Make sure proxy server is running
2. Check browser console for exact error
3. Try accessing http://localhost:3000 directly in browser

### Proxy works but AI still fails

**Check API key:**
- Go to Settings in Flutter app
- Make sure API key is saved
- Restart Flutter app

**Check proxy logs:**
- Look at proxy server terminal
- Should see request logs
- Any errors will be printed there

---

## Production Deployment (Future)

For deploying to production, you'll need to:

### Option 1: Deploy Proxy to Cloud

**Platforms:**
- Render.com (Free tier)
- Railway.app (Free tier)
- Vercel (Serverless functions)
- Heroku (Paid)

**Steps:**
1. Push proxy code to GitHub
2. Connect to deployment platform
3. Update Flutter to use production URL:
```dart
static const String _proxyUrl = 'https://your-proxy.render.com/api/claude/messages';
```

### Option 2: Use Cloud Functions

**Firebase Functions:**
```javascript
exports.claudeProxy = functions.https.onRequest((request, response) => {
  // Proxy logic here
});
```

**Pros:** Auto-scaling, pay-per-use
**Cons:** More complex setup

---

## Development Workflow

### Daily Development

**1. Start proxy (once per dev session):**
```bash
cd claude-proxy-server
npm start
```

**2. Start Flutter:**
```bash
cd ai_mentor_coach
flutter run -d chrome
```

**3. Develop normally** - AI features now work!

### Tips

- Keep proxy terminal visible to see request logs
- Proxy auto-restarts on code changes (if using nodemon)
- Both servers can run simultaneously

---

## Security Notes

### Development
- Proxy runs on localhost only
- Only accessible from your machine
- Safe for development

### Production
- Add authentication to proxy
- Limit CORS to your domain only
- Add rate limiting
- Monitor API usage

**Example production CORS:**
```javascript
app.use(cors({
  origin: 'https://yourapp.com',  // Your Flutter web URL
  methods: ['POST'],
}));
```