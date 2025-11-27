const mongoose = require('mongoose');
require('dotenv').config();

async function cleanupDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Drop the sessions collection to remove all old indexes
    const db = mongoose.connection.db;
    
    try {
      await db.collection('sessions').drop();
      console.log('Dropped sessions collection');
    } catch (error) {
      console.log('Collection may not exist, continuing...');
    }

    console.log('Database cleanup complete!');
    process.exit(0);
  } catch (error) {
    console.error('Error cleaning database:', error);
    process.exit(1);
  }
}

cleanupDatabase();
