require('dotenv').config();
const app = require('./app');
const { createServer } = require('http');
const { initWebSocket } = require('./websocket/chatSocket');
const { logger } = require('./config/logger');
const { prisma } = require('./config/database');

const PORT = process.env.PORT || 5001;

async function connectWithRetry(maxRetries = 5) {
  for (let i = 1; i <= maxRetries; i++) {
    try {
      await prisma.$connect();
      logger.info('Database connected successfully');
      return;
    } catch (err) {
      logger.error(`Database connection attempt ${i}/${maxRetries} failed`, { error: err.message });
      if (i === maxRetries) {
        logger.error('All database connection attempts failed');
        process.exit(1);
      }
      // Wait before retrying (exponential backoff)
      await new Promise((r) => setTimeout(r, i * 2000));
    }
  }
}

async function start() {
  await connectWithRetry();

  // Create HTTP server and attach WebSocket
  const server = createServer(app);
  initWebSocket(server);

  server.listen(PORT, '0.0.0.0', () => {
    logger.info(`Human Contact API server running on port ${PORT}`, {
      env: process.env.NODE_ENV,
      port: PORT,
    });
  });

  // Graceful shutdown
  const shutdown = async (signal) => {
    logger.info(`${signal} received, shutting down gracefully...`);
    server.close(async () => {
      await prisma.$disconnect();
      logger.info('Server shut down');
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

start();
