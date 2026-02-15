const express = require('express');
const { z } = require('zod');
const { authenticate } = require('../middleware/auth');
const { prisma } = require('../config/database');
const { sendToUser } = require('../websocket/chatSocket');
const { logger } = require('../config/logger');

const router = express.Router();
router.use(authenticate);

const REVEAL_WINDOW_MS = 5 * 60 * 1000;   // 5 minutes to view
const ARCHIVE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

const requestSchema = z.object({
  connectionId: z.string().uuid(),
  shareEmail: z.boolean(),
  sharePhone: z.boolean(),
  wantsEmail: z.boolean(),
  wantsPhone: z.boolean(),
});

const approveSchema = z.object({
  shareEmail: z.boolean(),
  sharePhone: z.boolean(),
});

/**
 * POST /api/v1/exchange
 * Initiate a contact exchange request
 */
router.post('/', async (req, res, next) => {
  try {
    const { connectionId, shareEmail, sharePhone, wantsEmail, wantsPhone } = requestSchema.parse(req.body);

    // Must share at least one field and want at least one
    if (!shareEmail && !sharePhone) {
      return res.status(400).json({ error: 'You must offer to share at least one contact method' });
    }
    if (!wantsEmail && !wantsPhone) {
      return res.status(400).json({ error: 'You must request at least one contact method' });
    }

    // Validate connection is ACTIVE
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
      return res.status(404).json({ error: 'Active connection not found' });
    }

    // Check no pending exchange already exists
    const existing = await prisma.contactExchange.findFirst({
      where: {
        connectionId,
        status: 'PENDING',
      },
    });

    if (existing) {
      return res.status(409).json({ error: 'An exchange request is already pending', exchangeId: existing.id });
    }

    // Figure out who is requester/recipient in the exchange
    const isConnectionRequester = connection.requesterId === req.userId;
    const recipientId = isConnectionRequester ? connection.recipientId : connection.requesterId;

    const exchange = await prisma.contactExchange.create({
      data: {
        connectionId,
        requesterId: req.userId,
        recipientId,
        reqShareEmail: shareEmail,
        reqSharePhone: sharePhone,
        reqWantsEmail: wantsEmail,
        reqWantsPhone: wantsPhone,
        status: 'PENDING',
      },
    });

    // Notify recipient via WebSocket
    sendToUser(recipientId, {
      type: 'exchange:request',
      data: {
        exchangeId: exchange.id,
        connectionId,
        requesterId: req.userId,
        offersEmail: shareEmail,
        offersPhone: sharePhone,
        wantsEmail,
        wantsPhone,
      },
    });

    logger.info('Contact exchange requested', { exchangeId: exchange.id, from: req.userId, to: recipientId });

    res.status(201).json({
      id: exchange.id,
      connectionId,
      status: 'PENDING',
      offersEmail: shareEmail,
      offersPhone: sharePhone,
      wantsEmail,
      wantsPhone,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: err.errors });
    }
    next(err);
  }
});

/**
 * PATCH /api/v1/exchange/:id/approve
 * Approve an exchange — triggers 5-min reveal countdown
 */
router.patch('/:id/approve', async (req, res, next) => {
  try {
    const { shareEmail, sharePhone } = approveSchema.parse(req.body);

    if (!shareEmail && !sharePhone) {
      return res.status(400).json({ error: 'You must share at least one contact method' });
    }

    const exchange = await prisma.contactExchange.findFirst({
      where: {
        id: req.params.id,
        recipientId: req.userId,
        status: 'PENDING',
      },
    });

    if (!exchange) {
      return res.status(404).json({ error: 'Pending exchange not found' });
    }

    const now = new Date();
    const revealExpiry = new Date(now.getTime() + REVEAL_WINDOW_MS);
    const archiveExpiry = new Date(now.getTime() + ARCHIVE_WINDOW_MS);

    // Update exchange + graduate the connection
    const [updatedExchange] = await prisma.$transaction([
      prisma.contactExchange.update({
        where: { id: exchange.id },
        data: {
          status: 'APPROVED',
          recShareEmail: shareEmail,
          recSharePhone: sharePhone,
          revealExpiresAt: revealExpiry,
          archiveExpiresAt: archiveExpiry,
          completedAt: now,
        },
      }),
      prisma.connection.update({
        where: { id: exchange.connectionId },
        data: {
          status: 'GRADUATED',
          contactExchanged: true,
        },
      }),
    ]);

    // Notify both users
    const notification = {
      type: 'exchange:approved',
      data: {
        exchangeId: exchange.id,
        connectionId: exchange.connectionId,
        revealExpiresAt: revealExpiry.toISOString(),
      },
    };
    sendToUser(exchange.requesterId, notification);
    sendToUser(exchange.recipientId, notification);

    logger.info('Contact exchange approved', { exchangeId: exchange.id });

    res.json({
      id: updatedExchange.id,
      status: 'APPROVED',
      revealExpiresAt: revealExpiry,
      archiveExpiresAt: archiveExpiry,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: err.errors });
    }
    next(err);
  }
});

/**
 * PATCH /api/v1/exchange/:id/decline
 */
router.patch('/:id/decline', async (req, res, next) => {
  try {
    const exchange = await prisma.contactExchange.findFirst({
      where: {
        id: req.params.id,
        recipientId: req.userId,
        status: 'PENDING',
      },
    });

    if (!exchange) {
      return res.status(404).json({ error: 'Pending exchange not found' });
    }

    await prisma.contactExchange.update({
      where: { id: exchange.id },
      data: { status: 'DECLINED' },
    });

    sendToUser(exchange.requesterId, {
      type: 'exchange:declined',
      data: { exchangeId: exchange.id, connectionId: exchange.connectionId },
    });

    logger.info('Contact exchange declined', { exchangeId: exchange.id });
    res.json({ id: exchange.id, status: 'DECLINED' });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/v1/exchange/:id/reveal
 * Get the actual contact details — only available during the reveal window
 */
router.get('/:id/reveal', async (req, res, next) => {
  try {
    const exchange = await prisma.contactExchange.findFirst({
      where: {
        id: req.params.id,
        status: 'APPROVED',
        OR: [
          { requesterId: req.userId },
          { recipientId: req.userId },
        ],
      },
      include: {
        requester: { select: { id: true, firstName: true, email: true, phone: true } },
        recipient: { select: { id: true, firstName: true, email: true, phone: true } },
      },
    });

    if (!exchange) {
      return res.status(404).json({ error: 'Approved exchange not found' });
    }

    // Check reveal window
    if (exchange.archiveExpiresAt && new Date() > new Date(exchange.archiveExpiresAt)) {
      return res.status(410).json({ error: 'Exchange reveal has expired' });
    }

    const isRequester = exchange.requesterId === req.userId;
    const iAmViewing = isRequester ? 'requester' : 'recipient';

    // Build what the current user gets to see
    let theirContact = {};
    const otherPerson = isRequester ? exchange.recipient : exchange.requester;

    if (isRequester) {
      // I'm the requester — I see what the recipient chose to share
      if (exchange.recShareEmail) theirContact.email = otherPerson.email;
      if (exchange.recSharePhone) theirContact.phone = otherPerson.phone;
    } else {
      // I'm the recipient — I see what the requester chose to share
      if (exchange.reqShareEmail) theirContact.email = otherPerson.email;
      if (exchange.reqSharePhone) theirContact.phone = otherPerson.phone;
    }

    // Build what I shared with them (for display)
    let myShared = {};
    const me = isRequester ? exchange.requester : exchange.recipient;
    if (isRequester) {
      if (exchange.reqShareEmail) myShared.email = me.email;
      if (exchange.reqSharePhone) myShared.phone = me.phone;
    } else {
      if (exchange.recShareEmail) myShared.email = me.email;
      if (exchange.recSharePhone) myShared.phone = me.phone;
    }

    const revealActive = exchange.revealExpiresAt && new Date() < new Date(exchange.revealExpiresAt);

    res.json({
      exchangeId: exchange.id,
      role: iAmViewing,
      otherPerson: {
        firstName: otherPerson.firstName,
        contact: theirContact,
      },
      myShared,
      revealActive,
      revealExpiresAt: exchange.revealExpiresAt,
      archiveExpiresAt: exchange.archiveExpiresAt,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/v1/exchange/connection/:connectionId
 * Get exchange status for a connection
 */
router.get('/connection/:connectionId', async (req, res, next) => {
  try {
    const exchange = await prisma.contactExchange.findFirst({
      where: {
        connectionId: req.params.connectionId,
        OR: [
          { requesterId: req.userId },
          { recipientId: req.userId },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!exchange) {
      return res.json({ hasExchange: false });
    }

    res.json({
      hasExchange: true,
      id: exchange.id,
      status: exchange.status,
      isRequester: exchange.requesterId === req.userId,
      revealExpiresAt: exchange.revealExpiresAt,
      archiveExpiresAt: exchange.archiveExpiresAt,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
