const auth = require('../services/authService');

const statuses = {
  INVALID_SIGNUP: 400,
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

async function logout(req, res) {
  await auth.logout(readToken(req));
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

module.exports = { signup, login, profile, logout, handleError };
