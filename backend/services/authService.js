const { createHash, randomBytes, scrypt, timingSafeEqual } = require('node:crypto');
const { promisify } = require('node:util');
const users = require('../repositories/userRepository');
const sessions = require('../repositories/sessionRepository');

const deriveKey = promisify(scrypt);
const sessionDuration = 24 * 60 * 60 * 1000;
const dummyHash = `${randomBytes(16).toString('hex')}:${randomBytes(64).toString('hex')}`;
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

class AuthError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function credentials(body) {
  if (typeof body?.email !== 'string' || typeof body.password !== 'string') return null;
  const email = body.email.trim().toLowerCase();
  const { password } = body;
  if (email.length > 254 || !emailPattern.test(email) || password.length === 0 ||
      Buffer.byteLength(password, 'utf8') > 1024) return null;
  return { email, password };
}

function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

async function createSession(user) {
  const token = randomBytes(32).toString('base64url');
  await sessions.create(hashToken(token), user.id, new Date(Date.now() + sessionDuration));
  return {
    token,
    expiresIn: sessionDuration / 1000,
    user: { id: user.id, email: user.email },
  };
}

async function signup(body) {
  const input = credentials(body);
  if (!input || [...input.password].length < 15) {
    throw new AuthError('INVALID_SIGNUP',
      'Enter a valid email and a password of at least 15 characters and at most 1024 bytes.');
  }
  const salt = randomBytes(16).toString('hex');
  const key = await deriveKey(input.password, salt, 64);
  const user = await users.create(input.email, `${salt}:${key.toString('hex')}`);
  if (!user) {
    throw new AuthError('DUPLICATE_EMAIL', 'An account already exists for this email. Log in instead.');
  }
  return createSession(user);
}

async function login(body) {
  const invalid = new AuthError('INVALID_LOGIN', 'Invalid email or password.');
  const input = credentials(body);
  if (!input) throw invalid;

  const user = await users.findCredentials(input.email);
  const [salt, key] = (user?.passwordHash ?? dummyHash).split(':');
  const candidate = await deriveKey(input.password, salt, 64);
  if (!timingSafeEqual(candidate, Buffer.from(key, 'hex')) || !user) throw invalid;

  return createSession(user);
}

async function profile(token) {
  const user = token && await sessions.findActiveUser(hashToken(token), new Date());
  if (!user) throw new AuthError('INVALID_SESSION', 'Invalid or expired session.');
  return user;
}

async function logout(token) {
  if (!token) throw new AuthError('INVALID_SESSION', 'A session token is required.');
  await sessions.revoke(hashToken(token));
}

module.exports = { signup, login, profile, logout, AuthError };
