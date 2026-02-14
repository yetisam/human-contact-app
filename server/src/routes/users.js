const express = require('express');
const { z } = require('zod');
const { prisma } = require('../config/database');
const { logger } = require('../config/logger');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Validation schemas
const profileSetupSchema = z.object({
  firstName: z.string().min(1).max(50).trim(),
  purposeStatement: z.string().min(50).max(200).trim(),
  meetingPreference: z.boolean(),
  city: z.string().min(1).max(100).trim().optional(),
  state: z.string().min(1).max(100).trim().optional(),
  country: z.string().length(2).default('AU'),
  locationLat: z.number().min(-90).max(90).optional(),
  locationLng: z.number().min(-180).max(180).optional(),
  interestIds: z.array(z.string().uuid()).min(3).max(10),
  avatarIcon: z.string().max(50).optional(),
});

const profileUpdateSchema = z.object({
  firstName: z.string().min(1).max(50).trim().optional(),
  purposeStatement: z.string().min(50).max(200).trim().optional(),
  meetingPreference: z.boolean().optional(),
  city: z.string().min(1).max(100).trim().optional(),
  state: z.string().min(1).max(100).trim().optional(),
  locationLat: z.number().min(-90).max(90).optional(),
  locationLng: z.number().min(-180).max(180).optional(),
  interestIds: z.array(z.string().uuid()).min(3).max(10).optional(),
  avatarIcon: z.string().max(50).optional(),
});

/**
 * GET /api/v1/users/me
 * Get current user's profile
 */
router.get('/me', async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: {
        id: true,
        email: true,
        emailVerified: true,
        phone: true,
        phoneVerified: true,
        firstName: true,
        age: true,
        city: true,
        state: true,
        country: true,
        purposeStatement: true,
        meetingPreference: true,
        avatarIcon: true,
        subscriptionTier: true,
        status: true,
        createdAt: true,
        interests: {
          include: {
            interest: {
              include: { category: true },
            },
          },
        },
        verificationRecords: {
          select: {
            type: true,
            status: true,
            completedAt: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Format interests for response
    const interests = user.interests.map((ui) => ({
      id: ui.interest.id,
      name: ui.interest.name,
      category: ui.interest.category.name,
      categoryIcon: ui.interest.category.icon,
    }));

    // Build verification status
    const verification = {
      email: user.emailVerified,
      phone: user.phoneVerified,
      governmentId: user.verificationRecords.some(
        (v) => v.type === 'GOVERNMENT_ID' && v.status === 'COMPLETED'
      ),
      backgroundCheck: user.verificationRecords.some(
        (v) => v.type === 'BACKGROUND_CHECK' && v.status === 'COMPLETED'
      ),
    };

    res.json({
      ...user,
      interests,
      verification,
      verificationRecords: undefined, // Don't expose raw records
    });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/v1/users/me/profile
 * Complete profile setup (after registration)
 */
router.put('/me/profile', async (req, res, next) => {
  try {
    const data = profileSetupSchema.parse(req.body);

    // Round location to ~1km for privacy
    const locationLat = data.locationLat
      ? Math.round(data.locationLat * 100) / 100
      : null;
    const locationLng = data.locationLng
      ? Math.round(data.locationLng * 100) / 100
      : null;

    // Verify all interest IDs exist
    const interests = await prisma.interest.findMany({
      where: { id: { in: data.interestIds } },
    });

    if (interests.length !== data.interestIds.length) {
      return res.status(400).json({ error: 'One or more interest IDs are invalid' });
    }

    // Update profile and interests in a transaction
    const user = await prisma.$transaction(async (tx) => {
      // Remove existing interests
      await tx.userInterest.deleteMany({
        where: { userId: req.userId },
      });

      // Create new interests
      await tx.userInterest.createMany({
        data: data.interestIds.map((interestId) => ({
          userId: req.userId,
          interestId,
        })),
      });

      // Update user profile
      return tx.user.update({
        where: { id: req.userId },
        data: {
          firstName: data.firstName,
          purposeStatement: data.purposeStatement,
          meetingPreference: data.meetingPreference,
          city: data.city,
          state: data.state,
          country: data.country,
          locationLat,
          locationLng,
          avatarIcon: data.avatarIcon,
        },
        select: {
          id: true,
          firstName: true,
          purposeStatement: true,
          meetingPreference: true,
          city: true,
          state: true,
          country: true,
          avatarIcon: true,
          status: true,
        },
      });
    });

    logger.info('Profile updated', { userId: req.userId });
    res.json({ user, interestCount: data.interestIds.length });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: err.errors });
    }
    next(err);
  }
});

/**
 * PATCH /api/v1/users/me/profile
 * Update specific profile fields
 */
router.patch('/me/profile', async (req, res, next) => {
  try {
    const data = profileUpdateSchema.parse(req.body);

    const updateData = {};
    if (data.firstName) updateData.firstName = data.firstName;
    if (data.purposeStatement) updateData.purposeStatement = data.purposeStatement;
    if (data.meetingPreference !== undefined) updateData.meetingPreference = data.meetingPreference;
    if (data.city) updateData.city = data.city;
    if (data.state) updateData.state = data.state;
    if (data.avatarIcon) updateData.avatarIcon = data.avatarIcon;
    if (data.locationLat) updateData.locationLat = Math.round(data.locationLat * 100) / 100;
    if (data.locationLng) updateData.locationLng = Math.round(data.locationLng * 100) / 100;

    // Handle interest update if provided
    if (data.interestIds) {
      const interests = await prisma.interest.findMany({
        where: { id: { in: data.interestIds } },
      });
      if (interests.length !== data.interestIds.length) {
        return res.status(400).json({ error: 'One or more interest IDs are invalid' });
      }

      await prisma.$transaction(async (tx) => {
        await tx.userInterest.deleteMany({ where: { userId: req.userId } });
        await tx.userInterest.createMany({
          data: data.interestIds.map((interestId) => ({
            userId: req.userId,
            interestId,
          })),
        });
      });
    }

    const user = await prisma.user.update({
      where: { id: req.userId },
      data: updateData,
      select: {
        id: true,
        firstName: true,
        purposeStatement: true,
        meetingPreference: true,
        city: true,
        state: true,
        avatarIcon: true,
        status: true,
      },
    });

    logger.info('Profile patched', { userId: req.userId });
    res.json({ user });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Validation failed', details: err.errors });
    }
    next(err);
  }
});

/**
 * GET /api/v1/users/interests
 * Get all available interest categories and tags
 */
router.get('/interests', async (_req, res, next) => {
  try {
    const categories = await prisma.interestCategory.findMany({
      orderBy: { sortOrder: 'asc' },
      include: {
        interests: {
          orderBy: { sortOrder: 'asc' },
          select: { id: true, name: true },
        },
      },
    });

    res.json({ categories });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
