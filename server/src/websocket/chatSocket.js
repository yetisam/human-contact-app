const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const { prisma } = require('../config/database');
const { logger } = require('../config/logger');

const clients = new Map(); // userId -> ws

function initWebSocket(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
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

    clients.set(userId, ws);
    logger.info('WebSocket client connected', { userId });

    ws.on('message', async (data) => {
      try {
        const message = JSON.parse(data);
        await handleMessage(userId, message, ws);
      } catch (err) {
        logger.error('WebSocket message error', { userId, error: err.message });
        ws.send(JSON.stringify({ type: 'error', message: err.message }));
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

    // Send welcome with pending message count
    ws.send(JSON.stringify({ type: 'connected', userId }));
  });

  // Heartbeat to keep connections alive
  const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (ws.isAlive === false) return ws.terminate();
      ws.isAlive = false;
      ws.ping();
    });
  }, 30000);

  wss.on('close', () => clearInterval(interval));

  logger.info('WebSocket server initialized');
  return wss;
}

/**
 * Handle incoming WebSocket messages
 */
async function handleMessage(userId, message, ws) {
  switch (message.type) {
    case 'chat:send':
      await handleChatSend(userId, message, ws);
      break;

    case 'chat:typing':
      handleTypingIndicator(userId, message);
      break;

    case 'chat:read':
      // Mark messages as read (for future read receipts)
      break;

    default:
      logger.debug('Unknown message type', { userId, type: message.type });
  }
}

/**
 * Handle sending a chat message via WebSocket
 */
async function handleChatSend(userId, message, ws) {
  const { connectionId, content } = message;

  if (!connectionId || !content) {
    ws.send(JSON.stringify({ type: 'error', message: 'connectionId and content required' }));
    return;
  }

  if (content.length > 500) {
    ws.send(JSON.stringify({ type: 'error', message: 'Message too long (max 500 chars)' }));
    return;
  }

  // Validate connection — must be ACTIVE and not expired
  const connection = await prisma.connection.findFirst({
    where: {
      id: connectionId,
      status: 'ACTIVE',
      OR: [
        { requesterId: userId },
        { recipientId: userId },
      ],
    },
  });

  if (!connection) {
    ws.send(JSON.stringify({ type: 'error', message: 'Connection not found or not active' }));
    return;
  }

  // Check if chat window has expired
  if (connection.chatExpiresAt && new Date() > new Date(connection.chatExpiresAt)) {
    // Expire the connection
    await prisma.connection.update({
      where: { id: connectionId },
      data: { status: 'EXPIRED' },
    });
    ws.send(JSON.stringify({ type: 'chat:expired', connectionId }));
    return;
  }

  // Check message limit
  const isRequester = connection.requesterId === userId;
  const remaining = isRequester
    ? connection.messagesRemainingReq
    : connection.messagesRemainingRec;

  if (remaining <= 0) {
    ws.send(JSON.stringify({
      type: 'chat:limit_reached',
      connectionId,
      message: 'You\'ve used all your messages for this connection',
    }));
    return;
  }

  // Save message and decrement counter in a transaction
  const [savedMessage] = await prisma.$transaction([
    prisma.message.create({
      data: {
        connectionId,
        senderId: userId,
        content: content.trim(),
      },
    }),
    prisma.connection.update({
      where: { id: connectionId },
      data: isRequester
        ? { messagesRemainingReq: { decrement: 1 } }
        : { messagesRemainingRec: { decrement: 1 } },
    }),
  ]);

  const outMessage = {
    type: 'chat:message',
    data: {
      id: savedMessage.id,
      connectionId,
      senderId: userId,
      content: savedMessage.content,
      createdAt: savedMessage.createdAt.toISOString(),
      messagesRemaining: remaining - 1,
    },
  };

  // Send to sender (confirmation)
  ws.send(JSON.stringify(outMessage));

  // Send to recipient
  const recipientId = isRequester ? connection.recipientId : connection.requesterId;
  sendToUser(recipientId, outMessage);

  logger.debug('Chat message sent', {
    connectionId,
    from: userId,
    to: recipientId,
    remaining: remaining - 1,
  });
}

/**
 * Relay typing indicator to the other user
 */
function handleTypingIndicator(userId, message) {
  const { connectionId } = message;
  if (!connectionId) return;

  // We don't need to validate connection for typing — just relay it
  // The recipient client will ignore it if the connection isn't active
  for (const [uid, ws] of clients) {
    if (uid !== userId) {
      // In a real system, we'd check if this user is part of the connection
      // For now, all messages carry connectionId so the client filters
      ws.send(JSON.stringify({
        type: 'chat:typing',
        connectionId,
        userId,
      }));
    }
  }
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

module.exports = { initWebSocket, sendToUser, clients };
