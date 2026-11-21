const mongoose = require('mongoose');
require('dotenv').config();

const app = require('./app');
const { ensureRegionalAttractions } = require('./services/attractionService');
const users = require('./repositories/userRepository');
const sessions = require('./repositories/sessionRepository');

const PORT = process.env.PORT || 3000;

async function start() {
  await mongoose.connect(process.env.MONGODB_URI);
  await Promise.all([users.ensureIndexes(), sessions.ensureIndexes(), ensureRegionalAttractions()]);
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

start().catch(async (error) => {
  console.error('Server startup failed:', error.name);
  await mongoose.disconnect();
  process.exitCode = 1;
});
