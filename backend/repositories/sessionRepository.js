const Session = require('../models/Session');
const users = require('./userRepository');

function create(tokenHash, userId, expiresAt, passwordResetAt) {
  return Session.create({ tokenHash, user: userId, expiresAt, passwordResetAt });
}

async function findActiveUser(tokenHash, now) {
  const session = await Session.findOne({
    tokenHash,
    expiresAt: { $gt: now },
  }).populate('user', 'email fullName phoneNumber +passwordResetAt').exec();
  if (!session?.user) return null;
  if (session.passwordResetAt?.getTime() !== session.user.passwordResetAt?.getTime()) return null;
  return users.profile(session.user);
}

function revoke(tokenHash) {
  return Session.deleteOne({ tokenHash }).exec();
}

function ensureIndexes() {
  return Session.createIndexes();
}

module.exports = { create, findActiveUser, revoke, ensureIndexes };
