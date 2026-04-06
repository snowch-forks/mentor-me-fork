// proxy-server.js - Cloud-deployed Claude API proxy
// API key is stored server-side in GCP Secret Manager (never sent from browser)

import express from 'express';
import fetch from 'node-fetch';

const app = express();
const PORT = 3000;

app.use(express.json({ limit: '10mb' }));

// Load API key from environment (injected by Cloud Run from Secret Manager)
const CLAUDE_API_KEY = process.env.CLAUDE_API_KEY;

if (!CLAUDE_API_KEY) {
  console.error('FATAL: CLAUDE_API_KEY environment variable not set.');
  console.error('Set it via GCP Secret Manager + Cloud Run secret binding.');
  process.exit(1);
}

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'MentorMe API Proxy' });
});

// Rate limiting - simple in-memory tracker (sufficient for 2 users)
const rateLimiter = new Map();
const RATE_LIMIT = 30; // requests per minute
const RATE_WINDOW = 60 * 1000; // 1 minute

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = rateLimiter.get(ip) || { count: 0, resetAt: now + RATE_WINDOW };

  if (now > entry.resetAt) {
    entry.count = 0;
    entry.resetAt = now + RATE_WINDOW;
  }

  entry.count++;
  rateLimiter.set(ip, entry);

  return entry.count <= RATE_LIMIT;
}

// Proxy endpoint - matches existing Flutter app expectations
app.post('/api/claude/messages', async (req, res) => {
  const clientIp = req.headers['x-forwarded-for'] || req.ip;

  if (!checkRateLimit(clientIp)) {
    return res.status(429).json({ error: 'Rate limit exceeded. Try again shortly.' });
  }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': CLAUDE_API_KEY, // Server-side key - never exposed to browser
        'anthropic-version': req.headers['anthropic-version'] || '2023-06-01',
      },
      body: JSON.stringify(req.body),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('Claude API error:', response.status, JSON.stringify(data).substring(0, 200));
      return res.status(response.status).json(data);
    }

    console.log(`✓ Claude API request from ${clientIp}`);
    res.json(data);

  } catch (error) {
    console.error('Proxy error:', error.message);
    res.status(500).json({
      error: 'Internal proxy error',
      message: error.message,
    });
  }
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Proxy listening on 127.0.0.1:${PORT} (server-side API key active)`);
});
