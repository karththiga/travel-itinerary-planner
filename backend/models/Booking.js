const mongoose = require('mongoose');

const statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

const bookingSchema = new mongoose.Schema({
  guestName: { type: String, required: true, maxlength: 120 },
  guestEmail: { type: String, required: true, maxlength: 254 },
  attraction: { type: mongoose.Schema.Types.ObjectId, ref: 'Attraction', required: true },
  attractionName: { type: String, required: true },
  visitDate: { type: String, required: true },
  partySize: { type: Number, required: true, min: 1, max: 1000 },
  status: { type: String, enum: statuses, default: 'pending', required: true },
}, { timestamps: true });

module.exports = { Booking: mongoose.model('Booking', bookingSchema), statuses };
