const User = require('../models/User');

async function create(email, passwordHash) {
  try {
    const user = await User.create({ email, passwordHash });
    return { id: user.id, email: user.email };
  } catch (error) {
    if (error.code === 11000) return null;
    throw error;
  }
}

async function findCredentials(email) {
  const user = await User.findOne({ email }).select('+passwordHash').exec();
  if (!user) return null;
  return { id: user.id, email: user.email, passwordHash: user.passwordHash };
}

function ensureIndexes() {
  return User.createIndexes();
}

module.exports = { create, findCredentials, ensureIndexes };
