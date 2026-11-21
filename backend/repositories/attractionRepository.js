const { createHash } = require('node:crypto');
const Attraction = require('../models/Attraction');

async function list() {
  const attractions = await Attraction.find({ archived: { $ne: true } }).select('-archived').exec();
  return attractions.map((attraction) => attraction.toJSON());
}

async function listByIds(ids) {
  const attractions = await Attraction.find({ _id: { $in: ids }, archived: { $ne: true } }).select('-archived').exec();
  return attractions.map((attraction) => attraction.toJSON());
}

async function insertMissing(places) {
  await Promise.all(places.map(async (place) => {
    const names = [place.name, ...place.aliases];
    if (await Attraction.exists({ regionalSeedKey: place.name })) return;

    const existing = await Attraction.findOne({ name: { $in: names } })
      .collation({ locale: 'en', strength: 2 })
      .select('name')
      .lean()
      .exec();
    if (existing) {
      await Attraction.updateOne(
        { _id: existing._id },
        {
          $set: { regionalSeedKey: place.name },
          $addToSet: { aliases: { $each: names.filter((name) => name !== existing.name) } },
        },
      ).exec();
      return;
    }

    const id = createHash('sha256')
      .update(`regional-attraction:${place.name}`)
      .digest('hex')
      .slice(0, 24);
    await Attraction.updateOne(
      { _id: id },
      { $setOnInsert: { ...place, regionalSeedKey: place.name } },
      { upsert: true, runValidators: true },
    ).exec();
  }));
}

function listForAdmin() {
  return Attraction.find().sort({ name: 1, _id: 1 }).exec();
}

function create(fields) {
  return Attraction.create(fields);
}

function update(id, changes) {
  return Attraction.findByIdAndUpdate(id, changes, { returnDocument: 'after', runValidators: true }).exec();
}

module.exports = { list, listByIds, insertMissing, listForAdmin, create, update };
