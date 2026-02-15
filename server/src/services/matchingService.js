const { prisma } = require('../config/database');
const { logger } = require('../config/logger');

/**
 * Matching algorithm: interest-weighted + proximity-based scoring
 *
 * Score = (interestScore * 0.6) + (proximityScore * 0.3) + (activityScore * 0.1)
 *
 * interestScore:  shared interests / max possible (Jaccard-like)
 * proximityScore: inverse distance decay (same city = 1.0, 50km+ drops off)
 * activityScore:  how recently active (24h = 1.0, 30d+ = 0.0)
 */

const WEIGHTS = {
  interest: 0.6,
  proximity: 0.3,
  activity: 0.1,
};

const MAX_DISTANCE_KM = 100; // Beyond this, proximity score = 0
const EARTH_RADIUS_KM = 6371;

/**
 * Haversine distance between two lat/lng points in km
 */
function haversineDistance(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a));
}

/**
 * Calculate interest overlap score (0-1)
 */
function interestScore(userInterestIds, candidateInterestIds) {
  const userSet = new Set(userInterestIds);
  const candidateSet = new Set(candidateInterestIds);
  let shared = 0;
  for (const id of candidateSet) {
    if (userSet.has(id)) shared++;
  }
  // Jaccard similarity: intersection / union
  const union = new Set([...userSet, ...candidateSet]).size;
  return union === 0 ? 0 : shared / union;
}

/**
 * Calculate proximity score (0-1)
 * Same city gets a bonus. Otherwise distance-based decay.
 */
function proximityScore(user, candidate) {
  // Same city? Perfect match
  if (user.city && candidate.city && user.city.toLowerCase() === candidate.city.toLowerCase()) {
    return 1.0;
  }

  // Both have coordinates? Use haversine
  if (user.locationLat && user.locationLng && candidate.locationLat && candidate.locationLng) {
    const distance = haversineDistance(
      user.locationLat,
      user.locationLng,
      candidate.locationLat,
      candidate.locationLng
    );
    if (distance >= MAX_DISTANCE_KM) return 0;
    return 1 - distance / MAX_DISTANCE_KM;
  }

  // Same state?
  if (user.state && candidate.state && user.state === candidate.state) {
    return 0.5;
  }

  // Same country?
  if (user.country && candidate.country && user.country === candidate.country) {
    return 0.2;
  }

  return 0;
}

/**
 * Calculate activity recency score (0-1)
 */
function activityScore(lastActiveAt) {
  if (!lastActiveAt) return 0;
  const hoursAgo = (Date.now() - new Date(lastActiveAt).getTime()) / (1000 * 60 * 60);
  if (hoursAgo <= 24) return 1.0;
  if (hoursAgo <= 72) return 0.8;
  if (hoursAgo <= 168) return 0.5; // 1 week
  if (hoursAgo <= 720) return 0.2; // 30 days
  return 0;
}

/**
 * Get match suggestions for a user
 * @param {string} userId
 * @param {object} options - { limit, offset, minScore }
 */
async function getMatchSuggestions(userId, options = {}) {
  const { limit = 20, offset = 0, minScore = 0.1 } = options;

  // Get the requesting user with their interests
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      interests: { select: { interestId: true } },
      blocksInitiated: { select: { blockedId: true } },
      blocksReceived: { select: { blockerId: true } },
      sentRequests: { select: { recipientId: true } },
      receivedRequests: { select: { requesterId: true } },
    },
  });

  if (!user) throw new Error('User not found');

  const userInterestIds = user.interests.map((i) => i.interestId);

  // Build exclusion set: blocked users, existing connections, self
  const excludeIds = new Set([
    userId,
    ...user.blocksInitiated.map((b) => b.blockedId),
    ...user.blocksReceived.map((b) => b.blockerId),
    ...user.sentRequests.map((c) => c.recipientId),
    ...user.receivedRequests.map((c) => c.requesterId),
  ]);

  // Get active candidates (verified users with interests)
  const candidates = await prisma.user.findMany({
    where: {
      status: 'ACTIVE',
      id: { notIn: [...excludeIds] },
    },
    include: {
      interests: {
        select: {
          interestId: true,
          interest: { select: { name: true, category: { select: { name: true, icon: true } } } },
        },
      },
    },
  });

  // Score each candidate
  const scored = candidates.map((candidate) => {
    const candidateInterestIds = candidate.interests.map((i) => i.interestId);

    const iScore = interestScore(userInterestIds, candidateInterestIds);
    const pScore = proximityScore(user, candidate);
    const aScore = activityScore(candidate.lastActiveAt);

    const totalScore =
      iScore * WEIGHTS.interest +
      pScore * WEIGHTS.proximity +
      aScore * WEIGHTS.activity;

    // Find shared interests for display
    const userSet = new Set(userInterestIds);
    const sharedInterests = candidate.interests
      .filter((i) => userSet.has(i.interestId))
      .map((i) => ({
        name: i.interest.name,
        category: i.interest.category.name,
        categoryIcon: i.interest.category.icon,
      }));

    return {
      id: candidate.id,
      firstName: candidate.firstName,
      city: candidate.city,
      state: candidate.state,
      purposeStatement: candidate.purposeStatement,
      meetingPreference: candidate.meetingPreference,
      avatarIcon: candidate.avatarIcon,
      lastActiveAt: candidate.lastActiveAt,
      score: Math.round(totalScore * 100) / 100,
      sharedInterests,
      sharedCount: sharedInterests.length,
      totalInterests: candidateInterestIds.length,
      breakdown: {
        interest: Math.round(iScore * 100),
        proximity: Math.round(pScore * 100),
        activity: Math.round(aScore * 100),
      },
    };
  });

  // Filter by minimum score and sort descending
  const filtered = scored
    .filter((s) => s.score >= minScore)
    .sort((a, b) => b.score - a.score);

  const total = filtered.length;
  const results = filtered.slice(offset, offset + limit);

  logger.debug('Match suggestions generated', {
    userId,
    candidatesEvaluated: candidates.length,
    matchesFound: total,
    returned: results.length,
  });

  return { matches: results, total, limit, offset };
}

module.exports = {
  getMatchSuggestions,
  // Export for testing
  interestScore,
  proximityScore,
  activityScore,
  haversineDistance,
};
