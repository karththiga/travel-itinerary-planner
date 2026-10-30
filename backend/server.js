const mongoose = require('mongoose');
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const Attraction = require('./models/Attraction');

const app = express();
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('MongoDB connected successfully');
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
  });



app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'Travel Itinerary Planner API is running'
  });
});


app.get('/api/attractions', async (req, res) => {
  try {
    const attractions = await Attraction.find();
    res.json(attractions);
  } catch (error) {
    res.status(500).json({
      message: 'Failed to retrieve attractions'
    });
  }
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});