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

app.use(helmet());
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PATCH', 'DELETE'], credentials: true }));
app.use(morgan('dev'));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'yt-uploader-backend' });
});

app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/uploads', require('./src/routes/uploadRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/payments', require('./src/routes/paymentRoutes'));
app.use('/api/schedules', require('./src/routes/scheduleRoutes'));

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal server error',
  });
});

async function start() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/yt-uploader');
    console.log('MongoDB connected');
    require('./src/services/scheduler');
    app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
  } catch (error) {
    console.error('Startup failed', error);
    process.exit(1);
  }
}

start();
