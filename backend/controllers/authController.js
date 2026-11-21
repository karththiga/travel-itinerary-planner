const auth = require('../services/authService');

const statuses = {
  RESET_UNAVAILABLE: 503,
  INVALID_SIGNUP: 400,
  INVALID_PROFILE: 400,
  INVALID_BOOKMARK: 400,
  INVALID_TRIP: 400,
  TRIP_LIMIT: 409,
  PROFILE_CONFLICT: 409,
  DUPLICATE_EMAIL: 409,
  INVALID_LOGIN: 401,
  INVALID_SESSION: 401,
};

function readToken(req) {
  return /^Bearer ([\w-]{43})$/i.exec(req.get('Authorization') ?? '')?.[1];
}

async function signup(req, res) {
  res.status(201).json(await auth.signup(req.body));
}

async function login(req, res) {
  res.json(await auth.login(req.body));
}

async function profile(req, res) {
  res.json({ user: await auth.profile(readToken(req)) });
}

async function updateProfile(req, res) {
  res.json({ user: await auth.updateProfile(readToken(req), req.body) });
}

async function listBookmarks(req, res) {
  res.json({ bookmarks: await auth.listBookmarks(readToken(req)) });
}

async function setBookmark(req, res) {
  await auth.setBookmark(readToken(req), req.body);
  res.sendStatus(204);
}

async function logout(req, res) {
  await auth.logout(readToken(req));
  res.sendStatus(204);
}

async function requestPasswordReset(req, res) {
  await auth.requestPasswordReset(req.body);
  res.sendStatus(202);
}

async function resetPassword(req, res) {
  await auth.resetPassword(req.body);
  res.sendStatus(204);
}

function handleError(error, req, res, next) {
  if (res.headersSent) return next(error);
  if (error instanceof auth.AuthError) {
    return res.status(statuses[error.code]).json({ message: error.message });
  }
  console.error('Authentication request failed:', error.name);
  return res.status(503).json({ message: 'Account service is unavailable. Try again shortly.' });
}

module.exports = { readToken, signup, login, profile, updateProfile, listBookmarks, setBookmark, logout, requestPasswordReset, resetPassword, handleError };
