const express = require('express');
const { z } = require('zod');
const { authenticate } = require('../middleware/auth');
const { prisma } = require('../config/database');
const { sendToUser } = require('../websocket/chatSocket');
const { logger } = require('../config/logger');

const router = express.Router();
router.use(authenticate);

const messageSchema = z.object({
  content: z.string().min(1).max(500),
});

/**
 * GET /api/v1/chat/:connectionId/messages
 * Get message history for a connection
 */
router.get('/:connectionId/messages', async (req, res, next) => {
  try {
    const { connectionId } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const before = req.query.before; // cursor-based pagination

    // Verify user is part of this connection
    const connection = await prisma.connection.findFirst({
      where: {
        id: connectionId,
        OR: [
          { requesterId: req.userId },
          { recipientId: req.userId },
        ],
      },
      select: {
        id: true,
        status: true,
        requesterId: true,
        recipientId: true,
        chatOpenedAt: true,
        chatExpiresAt: true,
        messagesRemainingReq: true,
        messagesRemainingRec: true,
        contactExchanged: true,
        requester: { select: { id: true, firstName: true, avatarIcon: true } },
        recipient: { select: { id: true, firstName: true, avatarIcon: true } },
      },
    });

    if (!connection) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    // Build query
    const where = {
      connectionId,
      deletedAt: null,
    };
    if (before) {
      where.createdAt = { lt: new Date(before) };
    }

    const messages = await prisma.message.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      select: {
        id: true,
        senderId: true,
        content: true,
        createdAt: true,
      },
    });

    // Calculate remaining messages for the current user
    const isRequester = connection.requesterId === req.userId;
    const myRemaining = isRequester
      ? connection.messagesRemainingReq
      : connection.messagesRemainingRec;

    // Check if chat is expired
    const isExpired = connection.chatExpiresAt
      ? new Date() > new Date(connection.chatExpiresAt)
      : false;

    res.json({
      connection: {
        id: connection.id,
        status: isExpired ? 'EXPIRED' : connection.status,
        chatOpenedAt: connection.chatOpenedAt,
        chatExpiresAt: connection.chatExpiresAt,
        contactExchanged: connection.contactExchanged,
        participants: {
          requester: connection.requester,
          recipient: connection.recipient,
        },
      },
      messages: messages.reverse(), // Return in chronological order
      myRemaining,
      hasMore: messages.length === limit,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/v1/chat/:connectionId/messages
 * Send a message (HTTP fallback when WebSocket isn't connected)
 */
router.post('/:connectionId/messages', async (req, res, next) => {
  try {
    const { connectionId } = req.params;
    const { content } = messageSchema.parse(req.body);

    // Validate connection
    const connection = await prisma.connection.findFirst({
      where: {
        id: connectionId,
        status: 'ACTIVE',
        OR: [
          { requesterId: req.userId },
          { recipientId: req.userId },
        ],
      },
    });

    if (!connection) {
      return res.status(404).json({ error: 'Connection not found or chat not active' });
    }

    // Check expiry
    if (connection.chatExpiresAt && new Date() > new Date(connection.chatExpiresAt)) {
      await prisma.connection.update({
        where: { id: connectionId },
        data: { status: 'EXPIRED' },
      });
      return res.status(410).json({ error: 'Chat window has expired' });
    }

    // Check message limit
    const isRequester = connection.requesterId === req.userId;
    const remaining = isRequester
      ? connection.messagesRemainingReq
      : connection.messagesRemainingRec;

    if (remaining <= 0) {
      return res.status(429).json({
        error: 'Message limit reached for this connection',
        remaining: 0,
      });
    }

    // Save message
    const [savedMessage] = await prisma.$transaction([
      prisma.message.create({
        data: {
          connectionId,
          senderId: req.userId,
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

    // Notify recipient via WebSocket
    const recipientId = isRequester ? connection.recipientId : connection.requesterId;
    sendToUser(recipientId, {
      type: 'chat:message',
      data: {
        id: savedMessage.id,
        connectionId,
        senderId: req.userId,
        content: savedMessage.content,
        createdAt: savedMessage.createdAt.toISOString(),
      },
    });

    logger.debug('Chat message sent via HTTP', { connectionId, from: req.userId });

    res.status(201).json({
      id: savedMessage.id,
      connectionId,
      senderId: req.userId,
      content: savedMessage.content,
      createdAt: savedMessage.createdAt,
      messagesRemaining: remaining - 1,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid message', details: err.errors });
    }
    next(err);
  }
});

/**
 * GET /api/v1/chat/:connectionId/status
 * Get chat status (remaining messages, expiry time)
 */
router.get('/:connectionId/status', async (req, res, next) => {
  try {
    const connection = await prisma.connection.findFirst({
      where: {
        id: req.params.connectionId,
        OR: [
          { requesterId: req.userId },
          { recipientId: req.userId },
        ],
      },
      select: {
        id: true,
        status: true,
        chatOpenedAt: true,
        chatExpiresAt: true,
        messagesRemainingReq: true,
        messagesRemainingRec: true,
        contactExchanged: true,
      },
    });

    if (!connection) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    const isExpired = connection.chatExpiresAt
      ? new Date() > new Date(connection.chatExpiresAt)
      : false;

    res.json({
      ...connection,
      status: isExpired ? 'EXPIRED' : connection.status,
      isExpired,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
