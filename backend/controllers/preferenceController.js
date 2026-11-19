const { receivePreferences } = require('../services/preferenceService');

function submit(req, res) {
  try {
    const preferences = receivePreferences(req.body);
    if (!preferences) {
      return res.status(400).json({ message: 'All travel preferences are required' });
    }
    return res.json({ message: 'Travel preferences received successfully', preferences });
  } catch (error) {
    console.error('Preference processing error:', error);
    return res.status(500).json({ message: 'Failed to process travel preferences' });
  }
}

module.exports = { submit };
