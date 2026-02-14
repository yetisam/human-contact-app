const jwt = require('jsonwebtoken');
const { prisma } = require('../config/database');

/**
 * Verify JWT token and attach user to request
 */
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

/**
 * Optional auth — attaches user if token present, continues if not
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.user = decoded;
  } catch (err) {
    // Token invalid, continue without auth
  }

  next();
}

/**
 * Require verified user (ID verification completed)
 */
async function requireVerified(req, res, next) {
  if (!req.userId) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: { status: true },
  });

  if (!user || user.status !== 'ACTIVE') {
    return res.status(403).json({ error: 'Account verification required' });
  }

  next();
}

module.exports = { authenticate, optionalAuth, requireVerified };
