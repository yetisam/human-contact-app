const express = require('express');
const { authenticate } = require('../middleware/auth');
const { getMatchSuggestions } = require('../services/matchingService');
const { prisma } = require('../config/database');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/v1/discovery/suggestions
 * Get match suggestions for the authenticated user
 * Query params: limit (default 20), offset (default 0), minScore (default 0.1)
 */
router.get('/suggestions', async (req, res, next) => {
  try {
    // Ensure user is active
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: { status: true },
    });

    if (!user || user.status !== 'ACTIVE') {
      return res.status(403).json({
        error: 'Please complete verification to see match suggestions',
      });
    }

    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = parseInt(req.query.offset) || 0;
    const minScore = parseFloat(req.query.minScore) || 0.1;

    const result = await getMatchSuggestions(req.userId, { limit, offset, minScore });

    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/v1/discovery/suggestions/:userId
 * Get detailed view of a specific match candidate
 */
router.get('/suggestions/:userId', async (req, res, next) => {
  try {
    const targetId = req.params.userId;

    // Check the user isn't blocked
    const block = await prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: req.userId, blockedId: targetId },
          { blockerId: targetId, blockedId: req.userId },
        ],
      },
    });

    if (block) {
      return res.status(404).json({ error: 'User not found' });
    }

    const candidate = await prisma.user.findFirst({
      where: {
        id: targetId,
        status: 'ACTIVE',
      },
      select: {
        id: true,
        firstName: true,
        city: true,
        state: true,
        purposeStatement: true,
        meetingPreference: true,
        avatarIcon: true,
        lastActiveAt: true,
        interests: {
          select: {
            interest: {
              select: {
                id: true,
                name: true,
                category: { select: { name: true, icon: true } },
              },
            },
          },
        },
      },
    });

    if (!candidate) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get current user's interests for comparison
    const myInterests = await prisma.userInterest.findMany({
      where: { userId: req.userId },
      select: { interestId: true },
    });
    const myInterestSet = new Set(myInterests.map((i) => i.interestId));

    const interests = candidate.interests.map((ui) => ({
      id: ui.interest.id,
      name: ui.interest.name,
      category: ui.interest.category.name,
      categoryIcon: ui.interest.category.icon,
      shared: myInterestSet.has(ui.interest.id),
    }));

    // Check if connection already exists
    const connection = await prisma.connection.findFirst({
      where: {
        OR: [
          { requesterId: req.userId, recipientId: targetId },
          { requesterId: targetId, recipientId: req.userId },
        ],
      },
      select: { id: true, status: true },
    });

    res.json({
      ...candidate,
      interests,
      sharedCount: interests.filter((i) => i.shared).length,
      connection: connection || null,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
