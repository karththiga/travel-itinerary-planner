const express = require('express');
const controller = require('../controllers/authController');
const trips = require('../controllers/savedTripController');
const limitAttempts = require('../middleware/limitAuthAttempts');

const router = express.Router();

router.use((req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});

router.post('/signup', limitAttempts, controller.signup);
router.post('/login', limitAttempts, controller.login);
router.post('/forgot-password', limitAttempts, controller.requestPasswordReset);
router.post('/reset-password', limitAttempts, controller.resetPassword);
router.get('/me', controller.profile);
router.patch('/me', limitAttempts, controller.updateProfile);
router.get('/me/bookmarks', controller.listBookmarks);
router.put('/me/bookmarks', controller.setBookmark);
router.get('/me/trips', trips.list);
router.post('/me/trips', trips.save);
router.delete('/me/trips/:id', trips.remove);
router.post('/logout', controller.logout);
router.use(controller.handleError);

module.exports = router;
