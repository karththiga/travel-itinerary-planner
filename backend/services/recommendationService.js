const attractions = require('../repositories/attractionRepository');

const tags = {
  History: ['history', 'heritage', 'archaeology'],
  Nature: ['nature', 'forest', 'waterfall'],
  Beach: ['beach', 'beaches', 'coast', 'coastal'],
  Wildlife: ['wildlife', 'safari', 'national park'],
  Culture: ['culture', 'cultural', 'heritage'],
  Adventure: ['adventure', 'hiking', 'trekking', 'rafting'],
  Food: ['food', 'culinary', 'dining', 'restaurant'],
  Religious: ['religious', 'religion', 'temple', 'pilgrimage'],
};

function validIds(value, limit) {
  return Array.isArray(value) && value.length <= limit &&
    value.every((id) => typeof id === 'string' && /^[a-f0-9]{24}$/i.test(id));
}

function readPreferences(body) {
  const { interests, tripDays, budget, groupType, transport, excluded = [], previous = [] } = body ?? {};
  if (!Array.isArray(interests) || interests.length < 1 || interests.length > 8 ||
      !interests.every((interest) => typeof interest === 'string' && Object.hasOwn(tags, interest)) ||
      !Number.isSafeInteger(tripDays) || tripDays < 1 || !Number.isFinite(budget) || budget <= 0 ||
      !['Solo', 'Couple', 'Family', 'Friends'].includes(groupType) ||
      !['Car', 'Public Transport', 'Motorbike', 'Walking'].includes(transport) ||
      !validIds(excluded, 500) || !validIds(previous, 12)) {
    return null;
  }
  return { interests: [...new Set(interests)], tripDays, budget, excluded, previous };
}

async function recommend({ interests, tripDays, budget, excluded, previous }) {
  const hidden = new Set(excluded);
  const seen = new Set(previous);
  const remaining = (await attractions.list()).flatMap((attraction) => {
    const id = String(attraction._id);
    const categories = attraction.category.toLowerCase().split(/[^a-z ]+/).map((tag) => tag.trim());
    const matches = interests.filter((interest) => tags[interest].some((tag) => categories.includes(tag)));
    if (hidden.has(id) || !matches.length || attraction.entryFee > budget ||
        attraction.estimatedVisitDuration / 480 > tripDays) return [];
    return [{ attraction, id, matches }];
  });
  const rankedScores = remaining.map(({ attraction }) => attraction.popularityScore)
    .filter((score) => score > 0).sort((a, b) => a - b);
  const lesserKnownThreshold = rankedScores.length >= 3
    ? rankedScores[Math.floor(rankedScores.length / 2)] : 0;
  const covered = new Set();
  const districts = new Set();
  const result = [];
  let includedDiscovery = false;
  const limit = Math.min(12, 2 + tripDays);
  const isDiscovery = ({ attraction }) => attraction.popularityScore > 0 &&
    attraction.popularityScore < lesserKnownThreshold;
  const score = (item) =>
    item.matches.filter((match) => !covered.has(match)).length * 8 +
    item.matches.length * 2 +
    (districts.has(item.attraction.district) ? 0 : 2) +
    (result.length && !includedDiscovery && isDiscovery(item) ? 3 : 0) -
    (seen.has(item.id) ? 4 : 0);

  while (remaining.length && result.length < limit) {
    remaining.sort((a, b) => score(b) - score(a) || a.id.localeCompare(b.id));
    const item = remaining.shift();
    item.matches.forEach((match) => covered.add(match));
    districts.add(item.attraction.district);
    const discovery = isDiscovery(item);
    includedDiscovery ||= discovery;
    result.push({ attraction: item.attraction, matches: item.matches, discovery });
  }
  return result;
}

function separation(a, b) {
  const radians = Math.PI / 180;
  const latitudeGap = (a.latitude - b.latitude) * radians;
  const longitudeGap = (a.longitude - b.longitude) * radians;
  return Math.sin(latitudeGap / 2) ** 2 +
    Math.cos(a.latitude * radians) * Math.cos(b.latitude * radians) *
    Math.sin(longitudeGap / 2) ** 2;
}

async function orderStops(ids) {
  if (!validIds(ids, 12) || !ids.length || new Set(ids).size !== ids.length) return null;
  const places = await attractions.listByIds(ids);
  const byId = new Map(places.map((place) => [String(place._id), place]));
  const remaining = ids.map((id) => byId.get(id));
  if (remaining.some((place) => !place)) return null;
  const ordered = [remaining.shift()];
  while (remaining.length) {
    const last = ordered.at(-1);
    remaining.sort((a, b) => separation(last, a) - separation(last, b));
    ordered.push(remaining.shift());
  }
  return ordered;
}

module.exports = { readPreferences, recommend, orderStops };
