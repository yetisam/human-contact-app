require('dotenv').config();
const app = require('./app');
const { createServer } = require('http');
const { initWebSocket } = require('./websocket/chatSocket');
const { logger } = require('./config/logger');
const { prisma } = require('./config/database');

const PORT = process.env.PORT || 5000;

async function start() {
  // Test database connection
  try {
    await prisma.$connect();
    logger.info('Database connected successfully');
  } catch (err) {
    logger.error('Failed to connect to database', { error: err.message });
    process.exit(1);
  }

  // Create HTTP server and attach WebSocket
  const server = createServer(app);
  initWebSocket(server);

  server.listen(PORT, () => {
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
