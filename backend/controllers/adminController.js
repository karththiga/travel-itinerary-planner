const admin = require('../services/adminService');
const { readToken } = require('./authController');

async function authorize(req, res, next) {
  res.set('Cache-Control', 'no-store');
  res.locals.admin = await admin.requireAdmin(readToken(req));
  next();
}

function session(req, res) {
  res.json({ user: res.locals.admin });
}

async function listAttractions(req, res) {
  res.json({ attractions: await admin.listAttractions() });
}

async function createAttraction(req, res) {
  res.status(201).json({ attraction: await admin.createAttraction(req.body) });
}

async function updateAttraction(req, res) {
  res.json({ attraction: await admin.updateAttraction(req.params.id, req.body) });
}

async function setArchived(req, res) {
  res.json({ attraction: await admin.setArchived(req.params.id, req.body?.archived) });
}

async function listBookings(req, res) {
  res.json({ bookings: await admin.listBookings() });
}

async function createBooking(req, res) {
  res.status(201).json({ booking: await admin.createBooking(req.body) });
}

async function updateBookingStatus(req, res) {
  res.json({ booking: await admin.updateBookingStatus(req.params.id, req.body?.status) });
}

function handleError(error, req, res, next) {
  if (res.headersSent) return next(error);
  if (error instanceof admin.AdminError) return res.status(error.status).json({ message: error.message });
  if (error.code === 'INVALID_SESSION') return res.status(401).json({ message: error.message });
  if (error.name === 'ValidationError') return res.status(400).json({ message: 'Check the supplied field values.' });
  console.error('Administration request failed:', error.name);
  return res.status(503).json({ message: 'Administration service is unavailable. Try again shortly.' });
}

module.exports = {
  authorize, session, listAttractions, createAttraction, updateAttraction,
  setArchived, listBookings, createBooking, updateBookingStatus, handleError,
};
