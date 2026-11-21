const { createHash } = require('node:crypto');
const auth = require('./authService');
const users = require('../repositories/userRepository');
const attractions = require('../repositories/attractionRepository');
const { readPreferences } = require('./recommendationService');

const tripLimit = 30;
const objectId = /^[a-f0-9]{24}$/;

async function list(token) {
  const user = await auth.profile(token);
  return users.listTrips(user.id);
}

function snapshot(place) {
  const text = (field, limit = 200) => String(place[field] ?? '').slice(0, limit);
  return {
    _id: String(place._id),
    name: text('name'),
    location: text('location'),
    district: text('district'),
    category: text('category'),
    description: text('description', 4000),
    openingTime: text('openingTime'),
    closingTime: text('closingTime'),
    environment: text('environment'),
    aliases: (place.aliases ?? []).slice(0, 20).map((alias) => alias.slice(0, 200)),
    latitude: place.latitude,
    longitude: place.longitude,
    estimatedVisitDuration: place.estimatedVisitDuration,
    entryFee: place.entryFee,
    freeAdmission: place.freeAdmission,
  };
}

async function save(token, body) {
  const user = await auth.profile(token);
  const input = body?.preferences;
  const parsed = readPreferences(input);
  const ids = body?.attractionIds;
  if (!parsed || !Array.isArray(ids) || ids.length < 1 || ids.length > 12 ||
      new Set(ids).size !== ids.length ||
      !ids.every((id) => typeof id === 'string' && objectId.test(id))) {
    throw new auth.AuthError('INVALID_TRIP', 'Choose a valid itinerary to save.');
  }

  const preferences = {
    interests: [...parsed.interests].sort(),
    tripDays: parsed.tripDays,
    budget: parsed.budget,
    groupType: input.groupType,
    transport: input.transport,
  };
  const id = createHash('sha256').update(JSON.stringify([preferences, ids])).digest('hex');
  const existing = await users.findTrip(user.id, id);
  if (existing) return existing;
  const places = new Map((await attractions.listByIds(ids))
    .map((place) => [String(place._id), place]));
  if (ids.some((key) => !places.has(key))) {
    throw new auth.AuthError('INVALID_TRIP', 'An attraction is no longer available. Generate the trip again.');
  }

  const trip = { id, preferences, stops: ids.map((key) => snapshot(places.get(key))) };
  if (await users.insertTrip(user.id, trip, tripLimit)) return trip;
  const concurrent = await users.findTrip(user.id, id);
  if (concurrent) return concurrent;
  throw new auth.AuthError('TRIP_LIMIT', 'Remove a saved trip before saving another. The limit is 30 trips.');
}

async function remove(token, id) {
  const user = await auth.profile(token);
  if (!/^[a-f0-9]{64}$/.test(id)) {
    throw new auth.AuthError('INVALID_TRIP', 'Invalid saved trip.');
  }
  await users.removeTrip(user.id, id);
}

module.exports = { list, save, remove };
