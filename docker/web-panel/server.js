/**
 * Puppy Stardew Server - Web Management Panel
 * Main server entry point
 */

const express = require('express');
const http = require('http');
const path = require('path');
const { WebSocketServer } = require('ws');
const auth = require('./auth');

// ─── Configuration ───────────────────────────────────────────────
const PORT = parseInt(process.env.PANEL_PORT || '18642', 10);
const PANEL_PASSWORD = process.env.PANEL_PASSWORD || 'admin123';

// Paths (inside container)
const DATA_DIR = process.env.PANEL_DATA_DIR || path.join(__dirname, 'data');
const STATUS_FILE = process.env.STATUS_FILE || '/home/steam/.local/share/puppy-stardew/status.json';
const LOG_DIR = process.env.LOG_DIR || '/home/steam/.local/share/puppy-stardew/logs';
const SAVES_DIR = process.env.SAVES_DIR || '/home/steam/.config/StardewValley/Saves';
const BACKUPS_DIR = process.env.BACKUPS_DIR || '/home/steam/.local/share/puppy-stardew/backups';
const GAME_DIR = process.env.GAME_DIR || '/home/steam/stardewvalley';
const ENV_FILE = process.env.ENV_FILE || '/home/steam/.env';

// Export paths for use by API modules
const config = {
  PORT,
  PANEL_PASSWORD,
  DATA_DIR,
  STATUS_FILE,
  LOG_DIR,
  SAVES_DIR,
  BACKUPS_DIR,
  GAME_DIR,
  ENV_FILE,
};
module.exports = config;

// ─── Express App ─────────────────────────────────────────────────
const app = express();
const server = http.createServer(app);

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// ─── Auth Routes (no JWT required) ─────────────────────────────��
app.post('/api/auth/login', auth.login);
app.get('/api/auth/verify', auth.verifyMiddleware, auth.verify);
app.post('/api/auth/password', auth.verifyMiddleware, auth.changePassword);

// ─── API Routes (JWT required) ──────────────────────────────────
// Status API
const statusAPI = require('./api/status');
app.get('/api/status', auth.verifyMiddleware, statusAPI.getStatus);

// Logs API
const logsAPI = require('./api/logs');
app.get('/api/logs', auth.verifyMiddleware, logsAPI.getLogs);

// Players API
const playersAPI = require('./api/players');
app.get('/api/players', auth.verifyMiddleware, playersAPI.getPlayers);

// Saves API
const savesAPI = require('./api/saves');
app.get('/api/saves', auth.verifyMiddleware, savesAPI.getSaves);
app.get('/api/saves/backups', auth.verifyMiddleware, savesAPI.getBackups);
app.post('/api/saves/backup', auth.verifyMiddleware, savesAPI.createBackup);
app.get('/api/saves/download/:filename', auth.verifyMiddleware, savesAPI.downloadBackup);

// Config API
const configAPI = require('./api/config');
app.get('/api/config', auth.verifyMiddleware, configAPI.getConfig);
app.put('/api/config', auth.verifyMiddleware, configAPI.updateConfig);

// Server control API
app.post('/api/server/restart', auth.verifyMiddleware, statusAPI.restartServer);

// Mods API
const modsAPI = require('./api/mods');
app.get('/api/mods', auth.verifyMiddleware, modsAPI.getMods);

// ─── Static Files ────────────────────────────────────────────────
app.use(express.static(path.join(__dirname, 'public')));

// SPA fallback - serve index.html for all non-API routes
app.get('*', (req, res) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: 'Not found' });
  }
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ─── WebSocket Server ────────────────────────────────────────────
const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws, req) => {
  // Parse token from query string
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const token = url.searchParams.get('token');

  if (!token || !auth.verifyToken(token)) {
    ws.close(4001, 'Unauthorized');
    return;
  }

  console.log('[WebSocket] Client connected');

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString());
      handleWebSocketMessage(ws, msg);
    } catch (e) {
      ws.send(JSON.stringify({ type: 'error', message: 'Invalid message format' }));
    }
  });

  ws.on('close', () => {
    console.log('[WebSocket] Client disconnected');
    // Clean up any log subscriptions or terminal sessions
    if (ws._logWatcher) {
      ws._logWatcher.close();
      ws._logWatcher = null;
    }
    if (ws._terminalProc) {
      ws._terminalProc.kill();
      ws._terminalProc = null;
    }
  });
});

function handleWebSocketMessage(ws, msg) {
  switch (msg.type) {
    case 'subscribe':
      if (msg.channel === 'logs') {
        logsAPI.subscribeLogs(ws, msg.filter || 'all');
      } else if (msg.channel === 'status') {
        statusAPI.subscribeStatus(ws);
      }
      break;

    case 'unsubscribe':
      if (msg.channel === 'logs' && ws._logWatcher) {
        ws._logWatcher.close();
        ws._logWatcher = null;
      }
      break;

    case 'terminal:input':
      const terminalAPI = require('./api/terminal');
      terminalAPI.handleInput(ws, msg.data);
      break;

    case 'terminal:open':
      const terminalAPI2 = require('./api/terminal');
      terminalAPI2.openTerminal(ws);
      break;

    case 'terminal:close':
      if (ws._terminalProc) {
        ws._terminalProc.kill();
        ws._terminalProc = null;
      }
      break;

    default:
      ws.send(JSON.stringify({ type: 'error', message: `Unknown message type: ${msg.type}` }));
  }
}

// ─── Initialize & Start ──────────────────────────────────────────
async function start() {
  // Initialize auth (generate password hash on first run)
  await auth.initialize(DATA_DIR, PANEL_PASSWORD);

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`[Web Panel] ✅ Management panel running on http://0.0.0.0:${PORT}`);
    console.log(`[Web Panel] Default password: ${PANEL_PASSWORD} (change it after first login!)`);
  });
}

start().catch((err) => {
  console.error('[Web Panel] Failed to start:', err);
  process.exit(1);
});
