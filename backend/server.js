const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '.env') });

const NODE_ENV = process.env.NODE_ENV || 'development';
const IS_PRODUCTION = NODE_ENV === 'production';

const app = express();
const PORT = process.env.PORT || 5000;

let server;
let isShuttingDown = false;

// ---------------------------------------------------------------------------
// Security & Core Middleware
// ---------------------------------------------------------------------------
app.disable('x-powered-by');
app.set('trust proxy', 1);

app.use(helmet());

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'PUT'],
  credentials: true,
}));

app.use(morgan(IS_PRODUCTION ? 'combined' : 'dev'));

app.use(express.json({ limit: '50mb' }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use(express.urlencoded({
  extended: true,
  limit: '50mb',
}));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

function formatBytes(bytes) {
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
}

function getDbStatusText(state) {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };
  return states[state] || 'unknown';
}

function formatUptime(seconds) {
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return `${d}d ${h}h ${m}m ${s}s`;
}

app.get('/health', (req, res) => {
  const mem = process.memoryUsage();

  res.status(200).json({
    success: true,
    service: 'yt-uploader-backend',
    status: 'running',
    environment: NODE_ENV,
    uptime: formatUptime(process.uptime()),
    memory: {
      rss: formatBytes(mem.rss),
      heapUsed: formatBytes(mem.heapUsed),
      heapTotal: formatBytes(mem.heapTotal),
    },
    database: getDbStatusText(mongoose.connection.readyState),
    node: process.version,
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/uploads', require('./src/routes/uploadRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/payments', require('./src/routes/paymentRoutes'));
app.use('/api/payment-settings', require('./src/routes/paymentSettingsRoutes'));
app.use('/api/payment', require('./src/routes/paymentSettingsRoutes'));
app.use('/api/admin/payment-settings', require('./src/routes/paymentSettingsRoutes'));
app.use('/api/payment-requests', require('./src/routes/paymentRequestRoutes'));
app.use('/api/wallet', require('./src/routes/walletRoutes'));
app.use('/api/schedules', require('./src/routes/scheduleRoutes'));

app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

app.use((err, req, res, next) => {
  const status = err.status || err.statusCode || 500;

  console.error('❌ Error:', err.message);
  if (!IS_PRODUCTION && err.stack) {
    console.error(err.stack);
  }

  const response = {
    success: false,
    message: err.message || 'Internal Server Error',
  };

  if (!IS_PRODUCTION) {
    response.stack = err.stack;
  }

  res.status(status).json(response);
});

mongoose.connection.on('connected', () => {
  console.log('✅ MongoDB connected');
});

mongoose.connection.on('disconnected', () => {
  console.warn('⚠️  MongoDB disconnected');
});

mongoose.connection.on('reconnected', () => {
  console.log('🔄 MongoDB reconnected');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ MongoDB connection error:', err.message);
});

function validateEnv() {
  const required = [
    'MONGO_URI',
    'JWT_SECRET',
    'ENCRYPTION_KEY',
    // Web Client 1 — Google Login / Authentication
    'GOOGLE_CLIENT_ID',
    'GOOGLE_CLIENT_SECRET',
    // Web Client 2 — YouTube OAuth (channel authorization, uploads, refresh tokens)
    'YOUTUBE_CLIENT_ID',
    'YOUTUBE_CLIENT_SECRET',
  ];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variable(s): ${missing.join(', ')}. Please add them in Render Environment Variables.`
    );
  }

  if (process.env.GOOGLE_CLIENT_ID === process.env.YOUTUBE_CLIENT_ID) {
    throw new Error(
      'GOOGLE_CLIENT_ID and YOUTUBE_CLIENT_ID must be different OAuth clients. Google Login and YouTube OAuth cannot share the same client.'
    );
  }
}

async function connectDatabase() {
  await mongoose.connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 10000,
    connectTimeoutMS: 10000,
    maxPoolSize: 10,
    minPoolSize: 1,
    socketTimeoutMS: 45000,
    autoIndex: !IS_PRODUCTION,
  });
}

async function start() {
  try {
    console.log('🚀 Starting yt-uploader-backend...');
    console.log(`🌍 Environment: ${NODE_ENV}`);

    validateEnv();
    console.log('✅ Environment variables validated (Mongo, Google Login, YouTube OAuth)');

    await connectDatabase();

    require('./src/services/scheduler');
    console.log('⏱️  Scheduler started');

    server = app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
    });

    server.on('error', (err) => {
      console.error('❌ HTTP server error:', err.message);
      process.exit(1);
    });

  } catch (error) {
    console.error('❌ Startup Failed');
    console.error(error.message);
    process.exit(1);
  }
}

async function shutdown(signal) {
  if (isShuttingDown) return;
  isShuttingDown = true;

  console.log(`\n🛑 Received ${signal}. Shutting down gracefully...`);

  const forceExitTimer = setTimeout(() => {
    console.error('❌ Forced shutdown due to timeout');
    process.exit(1);
  }, 15000);

  try {
    if (server) {
      await new Promise((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      });
      console.log('✅ HTTP server closed');
    }

    await mongoose.connection.close();
    console.log('✅ MongoDB connection closed');

    clearTimeout(forceExitTimer);
    console.log('👋 Shutdown complete');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during shutdown:', error.message);
    clearTimeout(forceExitTimer);
    process.exit(1);
  }
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  shutdown('uncaughtException');
});

process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled Rejection:', reason);
  shutdown('unhandledRejection');
});

start();
