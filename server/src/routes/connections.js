const express = require('express');
const { z } = require('zod');
const { authenticate } = require('../middleware/auth');
const { prisma } = require('../config/database');
const { logger } = require('../config/logger');

const router = express.Router();
router.use(authenticate);

const connectSchema = z.object({
  recipientId: z.string().uuid(),
  introMessage: z.string().min(20).max(200),
});

/**
 * POST /api/v1/connections
 * Send a connection request
 */
router.post('/', async (req, res, next) => {
  try {
    const { recipientId, introMessage } = connectSchema.parse(req.body);

    if (recipientId === req.userId) {
      return res.status(400).json({ error: 'Cannot connect with yourself' });
    }

    // Check recipient exists and is active
    const recipient = await prisma.user.findFirst({
      where: { id: recipientId, status: 'ACTIVE' },
    });
    if (!recipient) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check for blocks
    const block = await prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: req.userId, blockedId: recipientId },
          { blockerId: recipientId, blockedId: req.userId },
        ],
      },
    });
    if (block) {
      return res.status(403).json({ error: 'Unable to connect with this user' });
    }

    // Check for existing connection
    const existing = await prisma.connection.findFirst({
      where: {
        OR: [
          { requesterId: req.userId, recipientId },
          { requesterId: recipientId, recipientId: req.userId },
        ],
      },
    });
    if (existing) {
      return res.status(409).json({
        error: 'Connection already exists',
        connectionId: existing.id,
        status: existing.status,
      });
    }

    // Check daily connection request limit (free: 5/day, premium: 20/day)
    const requester = await prisma.user.findUnique({
      where: { id: req.userId },
      select: { subscriptionTier: true },
    });

    const dailyLimit = requester?.subscriptionTier === 'PREMIUM' ? 20 : 5;
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayRequests = await prisma.connection.count({
      where: {
        requesterId: req.userId,
        createdAt: { gte: todayStart },
      },
    });

    if (todayRequests >= dailyLimit) {
      return res.status(429).json({
        error: `Daily connection limit reached (${dailyLimit}/day)`,
        limit: dailyLimit,
        tier: requester?.subscriptionTier,
      });
    }

    // Create connection request
    const connection = await prisma.connection.create({
      data: {
        requesterId: req.userId,
        recipientId,
        introMessage,
        status: 'PENDING',
      },
      include: {
        requester: { select: { id: true, firstName: true, avatarIcon: true } },
        recipient: { select: { id: true, firstName: true, avatarIcon: true } },
      },
    });

    logger.info('Connection request sent', {
      connectionId: connection.id,
      from: req.userId,
      to: recipientId,
    });

    res.status(201).json(connection);
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: err.errors });
    }
    next(err);
  }
});

/**
 * GET /api/v1/connections
 * List user's connections (sent & received)
 * Query: status (PENDING|ACTIVE|GRADUATED|...), type (sent|received|all)
 */
router.get('/', async (req, res, next) => {
  try {
    const status = req.query.status?.toUpperCase();
    const type = req.query.type || 'all';
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;

    const where = {};

    if (type === 'sent') {
      where.requesterId = req.userId;
    } else if (type === 'received') {
      where.recipientId = req.userId;
    } else {
      where.OR = [
        { requesterId: req.userId },
        { recipientId: req.userId },
      ];
    }

    if (status) {
      where.status = status;
    }

    const [connections, total] = await Promise.all([
      prisma.connection.findMany({
        where,
        include: {
          requester: {
            select: { id: true, firstName: true, avatarIcon: true, city: true, purposeStatement: true },
          },
          recipient: {
            select: { id: true, firstName: true, avatarIcon: true, city: true, purposeStatement: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.connection.count({ where }),
    ]);

    res.json({ connections, total, limit, offset });
  } catch (err) {
    next(err);
  }
});

/**
 * PATCH /api/v1/connections/:id/accept
 * Accept a connection request — opens the 48h chat window
 */
router.patch('/:id/accept', async (req, res, next) => {
  try {
    const connection = await prisma.connection.findFirst({
      where: {
        id: req.params.id,
        recipientId: req.userId,
        status: 'PENDING',
      },
    });

    if (!connection) {
      return res.status(404).json({ error: 'Connection request not found' });
    }

    const now = new Date();
    const chatExpiry = new Date(now.getTime() + 48 * 60 * 60 * 1000); // 48 hours

    const updated = await prisma.connection.update({
      where: { id: connection.id },
      data: {
        status: 'ACTIVE',
        chatOpenedAt: now,
        chatExpiresAt: chatExpiry,
      },
      include: {
        requester: { select: { id: true, firstName: true, avatarIcon: true } },
        recipient: { select: { id: true, firstName: true, avatarIcon: true } },
      },
    });

    logger.info('Connection accepted', { connectionId: connection.id });
    res.json(updated);
  } catch (err) {
    next(err);
  }
});

/**
 * PATCH /api/v1/connections/:id/decline
 * Decline a connection request
 */
router.patch('/:id/decline', async (req, res, next) => {
  try {
    const connection = await prisma.connection.findFirst({
      where: {
        id: req.params.id,
        recipientId: req.userId,
        status: 'PENDING',
      },
    });

    if (!connection) {
      return res.status(404).json({ error: 'Connection request not found' });
    }

    const updated = await prisma.connection.update({
      where: { id: connection.id },
      data: { status: 'DECLINED' },
    });

    logger.info('Connection declined', { connectionId: connection.id });
    res.json({ message: 'Connection declined', id: updated.id });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
