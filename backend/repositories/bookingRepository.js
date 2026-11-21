const { Booking } = require('../models/Booking');

function list() {
  return Booking.find().sort({ visitDate: -1, _id: -1 }).exec();
}

function create(fields) {
  return Booking.create(fields);
}

function update(id, fields) {
  return Booking.findByIdAndUpdate(id, { $set: fields }, { returnDocument: 'after', runValidators: true }).exec();
}

module.exports = { list, create, update };
