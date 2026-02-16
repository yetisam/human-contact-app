const crypto = require('crypto');
const { prisma } = require('../config/database');
const { redis } = require('../config/redis');
const { logger } = require('../config/logger');

const CODE_LENGTH = 6;
const CODE_EXPIRY_SECONDS = 600; // 10 minutes
const MAX_ATTEMPTS = 5;
const COOLDOWN_SECONDS = 60; // 1 minute between sends

/**
 * Generate a random numeric code
 */
function generateCode() {
  return crypto.randomInt(100000, 999999).toString();
}

/**
 * Send email verification code
 */
async function sendEmailVerification(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, email: true, emailVerified: true },
  });

  if (!user) throw new Error('User not found');
  if (user.emailVerified) throw new Error('Email already verified');

  // Check cooldown
  const cooldownKey = `verify:cooldown:email:${userId}`;
  const hasCooldown = await redis.get(cooldownKey);
  if (hasCooldown) {
    throw new Error('Please wait before requesting another code');
  }

  const code = generateCode();
  const redisKey = `verify:email:${userId}`;
  const attemptsKey = `verify:attempts:email:${userId}`;

  // Store code in Redis with expiry
  await redis.setex(redisKey, CODE_EXPIRY_SECONDS, code);
  await redis.del(attemptsKey); // Reset attempts
  await redis.setex(cooldownKey, COOLDOWN_SECONDS, '1');

  // Send email (or log code until real email service is configured)
  if (process.env.SENDGRID_API_KEY) {
    await sendEmail(user.email, code);
  } else {
    logger.info('========================================');
    logger.info(`EMAIL VERIFICATION CODE for ${user.email}: ${code}`);
    logger.info('========================================');
  }

  // Record verification attempt
  await prisma.verificationRecord.upsert({
    where: {
      userId_type: { userId, type: 'EMAIL' },
    },
    update: {
      status: 'PENDING',
      completedAt: null,
      failureReason: null,
    },
    create: {
      userId,
      type: 'EMAIL',
      status: 'PENDING',
    },
  });

  return { expiresIn: CODE_EXPIRY_SECONDS };
}

/**
 * Verify email code
 */
async function verifyEmailCode(userId, code) {
  const redisKey = `verify:email:${userId}`;
  const attemptsKey = `verify:attempts:email:${userId}`;

  // Check attempts
  const attempts = parseInt(await redis.get(attemptsKey) || '0');
  if (attempts >= MAX_ATTEMPTS) {
    await redis.del(redisKey); // Invalidate code
    throw new Error('Too many attempts. Please request a new code.');
  }

  const storedCode = await redis.get(redisKey);
  if (!storedCode) {
    throw new Error('Code expired. Please request a new one.');
  }

  if (storedCode !== code) {
    await redis.incr(attemptsKey);
    await redis.expire(attemptsKey, CODE_EXPIRY_SECONDS);
    throw new Error('Invalid code');
  }

  // Success — mark email as verified
  await redis.del(redisKey);
  await redis.del(attemptsKey);

  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { emailVerified: true },
    }),
    prisma.verificationRecord.updateMany({
      where: { userId, type: 'EMAIL' },
      data: { status: 'COMPLETED', completedAt: new Date() },
    }),
  ]);

  logger.info('Email verified', { userId });
  return { verified: true };
}

/**
 * Send phone verification code
 */
async function sendPhoneVerification(userId, phone) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, phone: true, phoneVerified: true },
  });

  if (!user) throw new Error('User not found');

  // Check cooldown
  const cooldownKey = `verify:cooldown:phone:${userId}`;
  const hasCooldown = await redis.get(cooldownKey);
  if (hasCooldown) {
    throw new Error('Please wait before requesting another code');
  }

  // Update phone number if provided
  const phoneNumber = phone || user.phone;
  if (!phoneNumber) throw new Error('Phone number required');

  if (phone && phone !== user.phone) {
    await prisma.user.update({
      where: { id: userId },
      data: { phone: phoneNumber, phoneVerified: false },
    });
  }

  const code = generateCode();
  const redisKey = `verify:phone:${userId}`;
  const attemptsKey = `verify:attempts:phone:${userId}`;

  await redis.setex(redisKey, CODE_EXPIRY_SECONDS, code);
  await redis.del(attemptsKey);
  await redis.setex(cooldownKey, COOLDOWN_SECONDS, '1');

  // Send SMS (or log code until real SMS service is configured)
  if (process.env.TWILIO_ACCOUNT_SID) {
    await sendSMS(phoneNumber, code);
  } else {
    logger.info('========================================');
    logger.info(`PHONE VERIFICATION CODE for ${phoneNumber}: ${code}`);
    logger.info('========================================');
  }

  // Record verification attempt
  await prisma.verificationRecord.upsert({
    where: {
      userId_type: { userId, type: 'PHONE' },
    },
    update: {
      status: 'PENDING',
      completedAt: null,
      failureReason: null,
    },
    create: {
      userId,
      type: 'PHONE',
      status: 'PENDING',
    },
  });

  return { expiresIn: CODE_EXPIRY_SECONDS };
}

/**
 * Verify phone code
 */
async function verifyPhoneCode(userId, code) {
  const redisKey = `verify:phone:${userId}`;
  const attemptsKey = `verify:attempts:phone:${userId}`;

  const attempts = parseInt(await redis.get(attemptsKey) || '0');
  if (attempts >= MAX_ATTEMPTS) {
    await redis.del(redisKey);
    throw new Error('Too many attempts. Please request a new code.');
  }

  const storedCode = await redis.get(redisKey);
  if (!storedCode) {
    throw new Error('Code expired. Please request a new one.');
  }

  if (storedCode !== code) {
    await redis.incr(attemptsKey);
    await redis.expire(attemptsKey, CODE_EXPIRY_SECONDS);
    throw new Error('Invalid code');
  }

  // Success
  await redis.del(redisKey);
  await redis.del(attemptsKey);

  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { phoneVerified: true },
    }),
    prisma.verificationRecord.updateMany({
      where: { userId, type: 'PHONE' },
      data: { status: 'COMPLETED', completedAt: new Date() },
    }),
  ]);

  // Check if user should become ACTIVE (email + phone + ID all verified)
  await checkAndActivateUser(userId);

  logger.info('Phone verified', { userId });
  return { verified: true };
}

/**
 * Check if user has completed all required verifications and activate
 */
async function checkAndActivateUser(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      emailVerified: true,
      phoneVerified: true,
      status: true,
      verificationRecords: {
        where: { type: 'GOVERNMENT_ID', status: 'COMPLETED' },
      },
    },
  });

  if (!user) return;

  const hasIdVerification = user.verificationRecords.length > 0;

  // For MVP: activate when email + phone are verified
  // Full version: also require ID verification
  if (user.emailVerified && user.phoneVerified && user.status === 'PENDING_VERIFICATION') {
    await prisma.user.update({
      where: { id: userId },
      data: { status: 'ACTIVE' },
    });
    logger.info('User activated (email + phone verified)', { userId });
  }
}

/**
 * Placeholder: send email via SendGrid/SMTP
 */
async function sendEmail(to, code) {
  // TODO: Integrate SendGrid or nodemailer
  logger.warn('Email sending not configured', { to });
}

/**
 * Placeholder: send SMS via Twilio
 */
async function sendSMS(to, code) {
  // TODO: Integrate Twilio
  logger.warn('SMS sending not configured', { to });
}

module.exports = {
  sendEmailVerification,
  verifyEmailCode,
  sendPhoneVerification,
  verifyPhoneCode,
  checkAndActivateUser,
};
