const auth = require('./authService');
const users = require('../repositories/userRepository');
const attractions = require('../repositories/attractionRepository');
const bookings = require('../repositories/bookingRepository');
const { statuses } = require('../models/Booking');

class AdminError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

async function requireAdmin(token) {
  const user = await auth.profile(token);
  if (!await users.isAdmin(user.id)) throw new AdminError(403, 'Administrator access is required.');
  return user;
}

function objectId(id) {
  if (typeof id !== 'string' || !/^[a-f\d]{24}$/i.test(id)) {
    throw new AdminError(400, 'Invalid record ID.');
  }
  return id;
}

function text(value, label, max) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    throw new AdminError(400, `${label} must contain 1–${max} characters.`);
  }
  return value.trim();
}

function number(value, label, min, max = Infinity) {
  if (!Number.isFinite(value) || value < min || value > max) {
    throw new AdminError(400, `${label} is out of range.`);
  }
  return value;
}

function attractionFields(body = {}) {
  const input = body ?? {};
  const fields = {};
  for (const field of ['name', 'location', 'district', 'category']) {
    fields[field] = text(input[field], field, 160);
  }
  fields.latitude = number(input.latitude, 'Latitude', -90, 90);
  fields.longitude = number(input.longitude, 'Longitude', -180, 180);
  for (const field of ['description', 'openingTime', 'closingTime', 'environment']) {
    fields[field] = input[field] == null ? undefined : text(input[field], field, field === 'description' ? 4000 : 80);
  }
  for (const field of ['estimatedVisitDuration', 'entryFee', 'popularityScore']) {
    fields[field] = input[field] == null ? undefined : number(input[field], field, 0);
  }
  if (input.aliases != null && (!Array.isArray(input.aliases) || input.aliases.length > 30)) {
    throw new AdminError(400, 'Provide up to 30 aliases.');
  }
  fields.aliases = input.aliases?.map((alias) => text(alias, 'Alias', 160));
  if (input.freeAdmission != null && typeof input.freeAdmission !== 'boolean') {
    throw new AdminError(400, 'Invalid free admission value.');
  }
  fields.freeAdmission = input.freeAdmission ?? undefined;
  return fields;
}

function createAttraction(body) {
  return attractions.create(attractionFields(body));
}

async function updateAttraction(id, body) {
  const fields = attractionFields(body);
  const $set = {};
  const $unset = {};
  for (const [field, value] of Object.entries(fields)) {
    if (value === undefined) $unset[field] = 1;
    else $set[field] = value;
  }
  return found(await attractions.update(objectId(id), { $set, $unset }));
}

function found(record) {
  if (!record) throw new AdminError(404, 'Record not found.');
  return record;
}

async function setArchived(id, archived) {
  if (typeof archived !== 'boolean') throw new AdminError(400, 'Provide an archived flag.');
  return found(await attractions.update(objectId(id), { $set: { archived } }));
}

function visitDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new AdminError(400, 'Enter a valid visit date.');
  }
  const date = new Date(value);
  if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new AdminError(400, 'Enter a valid visit date.');
  }
  return value;
}

async function createBooking(body = {}) {
  const input = body ?? {};
  const guestName = text(input.guestName, 'Guest name', 120);
  const guestEmail = text(input.guestEmail, 'Guest email', 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(guestEmail)) {
    throw new AdminError(400, 'Enter a valid guest email.');
  }
  if (!Number.isInteger(input.partySize)) throw new AdminError(400, 'Enter a whole party size.');
  const partySize = number(input.partySize, 'Party size', 1, 1000);
  const date = visitDate(input.visitDate);
  const [attraction] = await attractions.listByIds([objectId(input.attraction)]);
  if (!attraction) throw new AdminError(400, 'Choose an active attraction.');
  return bookings.create({
    guestName, guestEmail, partySize, visitDate: date,
    attraction: attraction._id,
    attractionName: attraction.name,
  });
}

async function updateBookingStatus(id, status) {
  if (!statuses.includes(status)) throw new AdminError(400, 'Invalid booking status.');
  return found(await bookings.update(objectId(id), { status }));
}

module.exports = {
  AdminError, requireAdmin, createAttraction, updateAttraction, setArchived,
  listAttractions: attractions.listForAdmin, listBookings: bookings.list,
  createBooking, updateBookingStatus,
};
