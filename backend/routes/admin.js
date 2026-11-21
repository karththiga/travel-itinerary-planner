const router = require('express').Router();
const admin = require('../controllers/adminController');

router.use(admin.authorize);
router.get('/session', admin.session);
router.get('/attractions', admin.listAttractions);
router.post('/attractions', admin.createAttraction);
router.put('/attractions/:id', admin.updateAttraction);
router.patch('/attractions/:id/visibility', admin.setArchived);
router.get('/bookings', admin.listBookings);
router.post('/bookings', admin.createBooking);
router.patch('/bookings/:id/status', admin.updateBookingStatus);
router.use(admin.handleError);

module.exports = router;
