function receivePreferences(body) {
  const { interests, tripDays, budget, groupType, transport } = body;
  if (!Array.isArray(interests) || interests.length === 0 ||
      !tripDays || !budget || !groupType || !transport) {
    return null;
  }

  const preferences = { interests, tripDays, budget, groupType, transport };
  console.log('Traveller preferences received:');
  console.log(preferences);
  return preferences;
}

module.exports = { receivePreferences };
