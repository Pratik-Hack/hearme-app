const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB
connectDB();

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/doctors', require('./routes/doctors'));
app.use('/api/patients', require('./routes/patients'));
app.use('/api/rewards', require('./routes/rewards'));
app.use('/api/history', require('./routes/history'));
app.use('/api/mental-health', require('./routes/mental-health'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'hearme-server' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`HearMe server running on port ${PORT}`);
});
