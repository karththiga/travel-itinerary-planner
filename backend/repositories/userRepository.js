const User = require('../models/User');

async function create({ fullName, phoneNumber, email, passwordHash }) {
  try {
    const user = await User.create({ fullName, phoneNumber, email, passwordHash });
    return profile(user);
  } catch (error) {
    if (error.code === 11000) return null;
    throw error;
  }
}

async function findCredentials(email) {
  const user = await User.findOne({ email }).select('+passwordHash +passwordResetAt').exec();
  if (!user) return null;
  return { user: profile(user), passwordHash: user.passwordHash, passwordResetAt: user.passwordResetAt };
}

async function findAccount(id) {
  return User.findById(id).select('email +passwordHash').lean().exec();
}

async function updateProfile(id, previous, fields) {
  const user = await User.findOneAndUpdate(
    { _id: id, email: previous.email, passwordHash: previous.passwordHash },
    { $set: fields, ...(fields.email !== previous.email || fields.passwordHash
      ? { $unset: { passwordReset: 1 } } : {}) },
    { returnDocument: 'after', runValidators: true },
  ).exec();
  return user && profile(user);
}

async function issuePasswordReset(email, digest, expiresAt, cooldownBefore) {
  const result = await User.updateOne(
    { email, $or: [
      { 'passwordReset.expiresAt': { $exists: false } },
      { 'passwordReset.expiresAt': { $lte: cooldownBefore } },
    ] },
    { $set: { passwordReset: { digest, expiresAt } } },
  ).exec();
  return result.matchedCount === 1;
}

async function resetPassword(email, digest, passwordHash, now) {
  const result = await User.updateOne(
    { email, 'passwordReset.digest': digest, 'passwordReset.expiresAt': { $gt: now } },
    { $set: { passwordHash, passwordResetAt: now }, $unset: { passwordReset: 1 } },
  ).exec();
  return result.matchedCount === 1;
}

async function listBookmarks(id) {
  const user = await User.findById(id).select('bookmarks').lean().exec();
  return user?.bookmarks ?? [];
}

function setBookmark(id, key, saved) {
  const update = saved ? { $addToSet: { bookmarks: key } } : { $pull: { bookmarks: key } };
  return User.updateOne({ _id: id }, update).exec();
}

function profile({ id, email, fullName, phoneNumber }) {
  return { id, email, fullName, phoneNumber };
}

function ensureIndexes() {
  return User.createIndexes();
}

async function listTrips(id) {
  const user = await User.findById(id).select('savedTrips').lean().exec();
  return user?.savedTrips ?? [];
}

async function findTrip(id, tripId) {
  const user = await User.findOne({ _id: id, 'savedTrips.id': tripId })
    .select({ savedTrips: { $elemMatch: { id: tripId } } }).lean().exec();
  return user?.savedTrips?.[0];
}

async function insertTrip(id, trip, limit) {
  const result = await User.updateOne(
    { _id: id, 'savedTrips.id': { $ne: trip.id }, [`savedTrips.${limit - 1}`]: { $exists: false } },
    { $push: { savedTrips: { $each: [trip], $position: 0 } } },
  ).exec();
  return result.modifiedCount === 1;
}

function removeTrip(id, tripId) {
  return User.updateOne({ _id: id }, { $pull: { savedTrips: { id: tripId } } }).exec();
}

async function isAdmin(id) {
  return Boolean(await User.exists({ _id: id, role: 'admin' }));
}

module.exports = {
  isAdmin, listTrips, findTrip, insertTrip, removeTrip, create, findCredentials, profile, ensureIndexes, findAccount, updateProfile, listBookmarks, setBookmark, issuePasswordReset, resetPassword };
