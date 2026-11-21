const { createHash, randomBytes, scrypt, timingSafeEqual } = require('node:crypto');
const { promisify } = require('node:util');
const { sendPasswordReset, resetEmailConfigured } = require('./passwordResetEmail');
const users = require('../repositories/userRepository');
const sessions = require('../repositories/sessionRepository');

const deriveKey = promisify(scrypt);
const minimumPasswordLength = 8;
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

async function createSession(user, passwordResetAt) {
  const token = randomBytes(32).toString('base64url');
  await sessions.create(hashToken(token), user.id, new Date(Date.now() + sessionDuration), passwordResetAt);
  return {
    token,
    expiresIn: sessionDuration / 1000,
    user,
  };
}

function normalizePhoneNumber(value) {
  if (typeof value !== 'string') return null;
  const compact = value.trim().replace(/[ ().-]/g, '');
  const international = /^0[1-9][0-9]{8}$/.test(compact)
    ? `+94${compact.slice(1)}`
    : compact;
  return /^\+[1-9][0-9]{7,14}$/.test(international) ? international : null;
}

function profileFields(body, errorCode) {
  const fullName = typeof body?.fullName === 'string' ? body.fullName.trim() : '';
  if (!fullName || fullName.length > 120 || /[\u0000-\u001f\u007f]/u.test(fullName)) {
    throw new AuthError(errorCode, 'Enter a full name of up to 120 characters.');
  }

  const phoneNumber = normalizePhoneNumber(body?.phoneNumber);
  if (!phoneNumber) {
    throw new AuthError(errorCode, 'Enter a Sri Lankan phone number or include the international country code.');
  }

  return { fullName, phoneNumber };
}

async function signup(body) {
  const fields = profileFields(body, 'INVALID_SIGNUP');
  const input = credentials(body);
  if (!input || [...input.password].length < minimumPasswordLength) {
    throw new AuthError('INVALID_SIGNUP',
      `Enter a valid email and a password of at least ${minimumPasswordLength} characters and at most 1024 bytes.`);
  }
  const user = await users.create({
    ...fields,
    email: input.email,
    passwordHash: await hashPassword(input.password),
  });
  if (!user) {
    throw new AuthError('DUPLICATE_EMAIL', 'An account already exists for this email. Log in instead.');
  }
  return createSession(user);
}

async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const key = await deriveKey(password, salt, 64);
  return `${salt}:${key.toString('hex')}`;
}

async function matchesPassword(password, passwordHash) {
  const [salt, key] = passwordHash.split(':');
  const candidate = await deriveKey(password, salt, 64);
  return timingSafeEqual(candidate, Buffer.from(key, 'hex'));
}

async function login(body) {
  const invalid = new AuthError('INVALID_LOGIN', 'Invalid email or password.');
  const input = credentials(body);
  if (!input) throw invalid;

  const account = await users.findCredentials(input.email);
  if (!await matchesPassword(input.password, account?.passwordHash ?? dummyHash) || !account) {
    throw invalid;
  }

  return createSession(account.user, account.passwordResetAt);
}

async function profile(token) {
  const user = token && await sessions.findActiveUser(hashToken(token), new Date());
  if (!user) throw new AuthError('INVALID_SESSION', 'Invalid or expired session.');
  return user;
}

async function updateProfile(token, body) {
  const user = await profile(token);
  const fields = profileFields(body, 'INVALID_PROFILE');
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  if (email.length > 254 || !emailPattern.test(email)) {
    throw new AuthError('INVALID_PROFILE', 'Enter a valid email address.');
  }

  const password = body.newPassword ?? '';
  if (typeof password !== 'string' || Buffer.byteLength(password, 'utf8') > 1024 ||
      (password && [...password].length < minimumPasswordLength)) {
    throw new AuthError('INVALID_PROFILE', 'Enter a new password of at least 8 characters and at most 1024 bytes.');
  }

  const account = await users.findAccount(user.id);
  if (!account) throw new AuthError('INVALID_SESSION', 'Invalid or expired session.');
  if (email !== account.email || password) {
    const current = credentials({ email: account.email, password: body.currentPassword });
    if (!current || !await matchesPassword(current.password, account.passwordHash)) {
      throw new AuthError('INVALID_PROFILE', 'Enter your correct current password to change your email or password.');
    }
  }

  try {
    const updated = await users.updateProfile(user.id, account, {
      ...fields,
      email,
      ...(password ? { passwordHash: await hashPassword(password) } : {}),
    });
    if (!updated) {
      throw new AuthError('PROFILE_CONFLICT', 'Your account changed during this update. Try again.');
    }
    return updated;
  } catch (error) {
    if (error.code === 11000) {
      throw new AuthError('DUPLICATE_EMAIL', 'An account already uses this email address.');
    }
    throw error;
  }
}

async function listBookmarks(token) {
  const user = await profile(token);
  return users.listBookmarks(user.id);
}

async function setBookmark(token, body) {
  const user = await profile(token);
  if (typeof body?.key !== 'string' || !body.key || body.key.length > 512 ||
      typeof body.saved !== 'boolean') {
    throw new AuthError('INVALID_BOOKMARK', 'Invalid bookmark.');
  }
  await users.setBookmark(user.id, body.key, body.saved);
}

const resetLifetime = 15 * 60 * 1000;

function recoveryEmail(body) {
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : '';
  if (email.length > 254 || !emailPattern.test(email)) {
    throw new AuthError('INVALID_PROFILE', 'Enter a valid email address.');
  }
  return email;
}

async function requestPasswordReset(body) {
  const email = recoveryEmail(body);
  if (!resetEmailConfigured()) {
    throw new AuthError('RESET_UNAVAILABLE', 'Password recovery is currently unavailable.');
  }
  const code = randomBytes(24).toString('base64url');
  const expiresAt = new Date(Date.now() + resetLifetime);
  const cooldownBefore = new Date(expiresAt.getTime() - 60_000);
  if (await users.issuePasswordReset(email, hashToken(code), expiresAt, cooldownBefore)) {
    void sendPasswordReset(email, code).catch(() => {
      console.error('Password reset email delivery failed.');
    });
  }
}

async function resetPassword(body) {
  const email = recoveryEmail(body);
  const code = typeof body?.code === 'string' ? body.code.trim() : '';
  const input = credentials({ email, password: body?.password });
  if (!input || [...input.password].length < minimumPasswordLength) {
    throw new AuthError('INVALID_PROFILE', 'Enter a new password of at least 8 characters and at most 1024 bytes.');
  }
  if (!/^[\w-]{32}$/.test(code) ||
      !await users.resetPassword(email, hashToken(code), await hashPassword(input.password), new Date())) {
    throw new AuthError('INVALID_PROFILE', 'This reset code is invalid or expired. Request a new code.');
  }
}

async function logout(token) {
  if (!token) throw new AuthError('INVALID_SESSION', 'A session token is required.');
  await sessions.revoke(hashToken(token));
}

module.exports = { signup, login, profile, updateProfile, listBookmarks, setBookmark, logout, requestPasswordReset, resetPassword, AuthError };
