const express = require('express');
const controller = require('../controllers/authController');
const limitAttempts = require('../middleware/limitAuthAttempts');

const router = express.Router();

router.use((req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});

router.post('/signup', limitAttempts, controller.signup);
router.post('/login', limitAttempts, controller.login);
router.get('/me', controller.profile);
router.post('/logout', controller.logout);
router.use(controller.handleError);

module.exports = router;
