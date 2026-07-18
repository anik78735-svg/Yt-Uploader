const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 5000;

// Security
app.use(helmet());

// CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  credentials: true,
}));

// Logging
app.use(morgan('dev'));

// Body Parser
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({
  extended: true,
  limit: '50mb',
}));

// Rate Limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    service: 'yt-uploader-backend',
    status: 'running',
    uptime: process.uptime(),
  });
});

// Routes
app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/uploads', require('./src/routes/uploadRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/payments', require('./src/routes/paymentRoutes'));
app.use('/api/schedules', require('./src/routes/scheduleRoutes'));

// Error Handler
app.use((err, req, res, next) => {
  console.error(err);

  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

async function start() {
  try {
    // Check Mongo URI
    if (!process.env.MONGO_URI) {
      throw new Error(
        'MONGO_URI environment variable is missing. Please add it in Render Environment Variables.'
      );
    }

    // Connect MongoDB
    await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 10000,
      connectTimeoutMS: 10000,
    });

    console.log('✅ MongoDB Connected Successfully');

    // Start Scheduler
    require('./src/services/scheduler');

    // Start Server
    app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
    });

  } catch (error) {
    console.error('❌ Startup Failed');
    console.error(error.message);
    process.exit(1);
  }
}

// Graceful Shutdown
process.on('SIGINT', async () => {
  console.log('\nClosing MongoDB connection...');

  await mongoose.connection.close();

  console.log('MongoDB connection closed.');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nStopping server...');

  await mongoose.connection.close();

  console.log('MongoDB connection closed.');
  process.exit(0);
});

start();
