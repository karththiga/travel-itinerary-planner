const express = require('express');
const auth = require('./auth');
const attractions = require('../controllers/attractionController');
const preferences = require('../controllers/preferenceController');

const router = express.Router();

router.use('/auth', auth);
router.get('/attractions', attractions.list);
router.post('/preferences', preferences.submit);

module.exports = router;
