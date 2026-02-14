const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const { logger } = require('../config/logger');

const clients = new Map(); // userId -> ws

function initWebSocket(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    // Authenticate via query param token
    const url = new URL(req.url, `http://${req.headers.host}`);
    const token = url.searchParams.get('token');

    if (!token) {
      ws.close(4001, 'Authentication required');
      return;
    }

    let userId;
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      userId = decoded.userId;
    } catch {
      ws.close(4001, 'Invalid token');
      return;
    }

    // Register client
    clients.set(userId, ws);
    logger.info('WebSocket client connected', { userId });

    ws.on('message', (data) => {
      // Handle incoming messages — will be implemented with chat feature
      try {
        const message = JSON.parse(data);
        handleMessage(userId, message);
      } catch (err) {
        logger.error('WebSocket message error', { userId, error: err.message });
      }
    });

    ws.on('close', () => {
      clients.delete(userId);
      logger.info('WebSocket client disconnected', { userId });
    });

    ws.on('error', (err) => {
      logger.error('WebSocket error', { userId, error: err.message });
      clients.delete(userId);
    });

    // Send welcome
    ws.send(JSON.stringify({ type: 'connected', userId }));
  });

  logger.info('WebSocket server initialized');
}

function handleMessage(userId, message) {
  // Placeholder — chat messaging will be implemented here
  logger.debug('Received message', { userId, type: message.type });
}

/**
 * Send a message to a specific user
 */
function sendToUser(userId, data) {
  const ws = clients.get(userId);
  if (ws && ws.readyState === 1) {
    ws.send(JSON.stringify(data));
    return true;
  }
  return false;
}

module.exports = { initWebSocket, sendToUser };
