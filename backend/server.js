const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'Travel Itinerary Planner API is running'
  });
});

const attractions = [
  {
    id: 1,
    name: "Sigiriya",
    location: "Matale",
    category: "Historical",
    latitude: 7.9570,
    longitude: 80.7603
  },
  {
    id: 2,
    name: "Temple of the Tooth",
    location: "Kandy",
    category: "Religious",
    latitude: 7.2936,
    longitude: 80.6413
  },
  {
    id: 3,
    name: "Galle Fort",
    location: "Galle",
    category: "Historical",
    latitude: 6.0260,
    longitude: 80.2170
  }
];

app.get('/api/attractions', (req, res) => {
  res.json(attractions);
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});