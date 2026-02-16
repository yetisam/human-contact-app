const Redis = require('ioredis');
const { logger } = require('./logger');

// In-memory fallback when Redis isn't available
class MemoryStore {
  constructor() {
    this.store = new Map();
    this.timers = new Map();
  }

  async get(key) {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.value;
  }

  async set(key, value) {
    this.store.set(key, { value });
    return 'OK';
  }

  async setex(key, seconds, value) {
    this.store.set(key, { value, expiresAt: Date.now() + seconds * 1000 });
    return 'OK';
  }

  async del(key) {
    this.store.delete(key);
    return 1;
  }

  async incr(key) {
    const current = parseInt((await this.get(key)) || '0');
    const entry = this.store.get(key);
    const newVal = (current + 1).toString();
    this.store.set(key, { value: newVal, expiresAt: entry?.expiresAt });
    return current + 1;
  }

  async expire(key, seconds) {
    const entry = this.store.get(key);
    if (entry) {
      entry.expiresAt = Date.now() + seconds * 1000;
    }
    return 1;
  }
}

let redis;

if (process.env.REDIS_URL) {
  redis = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
  });

  redis.on('connect', () => {
    logger.info('Redis connected');
  });

  redis.on('error', (err) => {
    logger.error('Redis error', { error: err.message });
  });
} else {
  logger.info('Redis URL not set — using in-memory store');
  redis = new MemoryStore();
}

module.exports = { redis };
