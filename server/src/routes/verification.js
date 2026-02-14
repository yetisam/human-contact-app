const express = require('express');
const { z } = require('zod');
const { logger } = require('../config/logger');
const { authenticate } = require('../middleware/auth');
const {
  sendEmailVerification,
  verifyEmailCode,
  sendPhoneVerification,
  verifyPhoneCode,
} = require('../services/verificationService');

const router = express.Router();
router.use(authenticate);

const codeSchema = z.object({
  code: z.string().length(6).regex(/^\d+$/, 'Code must be 6 digits'),
});

const phoneSchema = z.object({
  phone: z.string().min(8).max(20).regex(/^\+?[\d\s-]+$/, 'Invalid phone number'),
});

/**
 * POST /api/v1/verification/email/send
 * Send email verification code
 */
router.post('/email/send', async (req, res, next) => {
  try {
    const result = await sendEmailVerification(req.userId);
    res.json({
      message: 'Verification code sent to your email',
      expiresIn: result.expiresIn,
    });
  } catch (err) {
    if (err.message.includes('already verified') || err.message.includes('wait')) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});

/**
 * POST /api/v1/verification/email/verify
 * Verify email code
 */
router.post('/email/verify', async (req, res, next) => {
  try {
    const { code } = codeSchema.parse(req.body);
    const result = await verifyEmailCode(req.userId, code);
    res.json({ message: 'Email verified successfully', ...result });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid code format', details: err.errors });
    }
    if (['Invalid code', 'expired', 'Too many'].some((s) => err.message.includes(s))) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});

/**
 * POST /api/v1/verification/phone/send
 * Send phone verification code
 */
router.post('/phone/send', async (req, res, next) => {
  try {
    const { phone } = phoneSchema.parse(req.body);
    const result = await sendPhoneVerification(req.userId, phone);
    res.json({
      message: 'Verification code sent to your phone',
      expiresIn: result.expiresIn,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid phone number', details: err.errors });
    }
    if (err.message.includes('wait')) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});

/**
 * POST /api/v1/verification/phone/verify
 * Verify phone code
 */
router.post('/phone/verify', async (req, res, next) => {
  try {
    const { code } = codeSchema.parse(req.body);
    const result = await verifyPhoneCode(req.userId, code);
    res.json({ message: 'Phone verified successfully', ...result });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid code format', details: err.errors });
    }
    if (['Invalid code', 'expired', 'Too many'].some((s) => err.message.includes(s))) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});

module.exports = router;
