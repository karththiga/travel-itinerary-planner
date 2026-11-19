const Session = require('../models/Session');

function create(tokenHash, userId, expiresAt) {
  return Session.create({ tokenHash, user: userId, expiresAt });
}

async function findActiveUser(tokenHash, now) {
  const session = await Session.findOne({
    tokenHash,
    expiresAt: { $gt: now },
  }).populate('user', 'email').exec();
  if (!session?.user) return null;
  const { id, email } = session.user;
  return { id, email };
}

function revoke(tokenHash) {
  return Session.deleteOne({ tokenHash }).exec();
}

function ensureIndexes() {
  return Session.createIndexes();
}

module.exports = { create, findActiveUser, revoke, ensureIndexes };
