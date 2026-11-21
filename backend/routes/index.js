const express = require('express');
const auth = require('./auth');
const attractions = require('../controllers/attractionController');
const preferences = require('../controllers/preferenceController');

const recommendations = require('../controllers/recommendationController');

const router = express.Router();

router.use('/auth', auth);
router.use('/admin', require('./admin'));
router.get('/attractions', attractions.list);
router.post('/preferences', preferences.submit);

router.post('/recommendations', recommendations.recommend, recommendations.handleError);
router.post('/travel-route', recommendations.route, recommendations.handleError);

module.exports = router;
