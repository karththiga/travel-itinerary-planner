const mongoose = require('mongoose');

const savedTripSchema = new mongoose.Schema({
  id: { type: String, required: true },
  preferences: { type: mongoose.Schema.Types.Mixed, required: true },
  stops: { type: [mongoose.Schema.Types.Mixed], required: true },
}, { _id: false, id: false });

const userSchema = new mongoose.Schema({
  fullName: { type: String, trim: true, maxlength: 120 },
  phoneNumber: { type: String, match: /^\+[1-9][0-9]{7,14}$/ },
  email: { type: String, required: true, unique: true },
  role: { type: String, enum: ['traveler', 'admin'], default: 'traveler', select: false },
  bookmarks: { type: [String], default: [] },
  savedTrips: { type: [savedTripSchema], default: [] },
  passwordReset: {
    digest: { type: String, select: false },
    expiresAt: { type: Date, select: false },
  },
  passwordResetAt: { type: Date, select: false },
  passwordHash: { type: String, required: true, select: false },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
