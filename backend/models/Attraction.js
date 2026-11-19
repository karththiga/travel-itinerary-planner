const mongoose = require('mongoose');

const attractionSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  location: {
    type: String,
    required: true
  },
  district: {
    type: String,
    required: true
  },
  category: {
    type: String,
    required: true
  },
  description: {
    type: String
  },
  latitude: {
    type: Number,
    required: true
  },
  longitude: {
    type: Number,
    required: true
  },
  openingTime: {
    type: String
  },
  closingTime: {
    type: String
  },
  estimatedVisitDuration: {
    type: Number
  },
  entryFee: {
    type: Number,
    default: 0
  },
  environment: {
    type: String,
    enum: ['Indoor', 'Outdoor', 'Both']
  },
  popularityScore: {
    type: Number,
    default: 0
  }
});

module.exports = mongoose.model('Attraction', attractionSchema);