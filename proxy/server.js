// server.js - Claude API Proxy Server
// This server forwards requests from Flutter Web to Claude API
// and adds CORS headers to allow browser access

import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins (adjust in production)
app.use(cors({
  origin: '*', // In production, specify your Flutter web URL
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'x-api-key', 'anthropic-version']
}));

app.use(express.json({ limit: '10mb' }));

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Claude API Proxy Server',
    endpoints: {
      messages: 'POST /api/claude/messages'
    }
  });
});

// Proxy endpoint for Claude API messages
app.post('/api/claude/messages', async (req, res) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({ 
      error: 'API key required in x-api-key header' 
    });
  }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': req.headers['anthropic-version'] || '2023-06-01',
      },
      body: JSON.stringify(req.body),
    });

    const data = await response.json();
    
    if (!response.ok) {
      console.error('Claude API error:', response.status, data);
      return res.status(response.status).json(data);
    }

    console.log('✓ Claude API request successful');
    res.json(data);
    
  } catch (error) {
    console.error('Proxy error:', error);
    res.status(500).json({ 
      error: 'Internal proxy error',
      message: error.message 
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ 
    error: 'Server error',
    message: err.message 
  });
});

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════╗
║  Claude API Proxy Server               ║
║  Running on http://localhost:${PORT}     ║
╚════════════════════════════════════════╝

Endpoints:
  GET  /                       - Health check
  POST /api/claude/messages    - Claude API proxy

Setup:
  1. Keep this server running
  2. Update Flutter app to use http://localhost:${PORT}
  3. Make requests from Flutter web app

Press Ctrl+C to stop
`);
});