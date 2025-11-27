const express = require('express');
const router = express.Router();
const User = require('../models/user.model');
const crypto = require('crypto');

// Create a new user (register)
router.post('/register', async (req, res) => {
  try {
    const { email, password, displayName } = req.body;
    
    if (!email || !password || !displayName) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }
    
    // Hash password
    const passwordHash = crypto
      .createHash('sha256')
      .update(password)
      .digest('hex');
    
    const user = new User({
      email,
      displayName,
      passwordHash
    });
    
    await user.save();
    
    // Don't return the password hash
    const userResponse = {
      id: user._id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt
    };
    
    res.status(201).json(userResponse);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Check password
    const passwordHash = crypto
      .createHash('sha256')
      .update(password)
      .digest('hex');
      
    if (passwordHash !== user.passwordHash) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Update last login time
    user.lastLoginAt = new Date();
    await user.save();
    
    // Create a simple token (in a real app, use JWT)
    const token = crypto
      .createHash('sha256')
      .update(user._id.toString() + new Date().toString())
      .digest('hex');
    
    const userResponse = {
      id: user._id,
      email: user.email,
      displayName: user.displayName,
      token
    };
    
    res.json(userResponse);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const user = await User.findById(id).select('-passwordHash');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update user
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { displayName } = req.body;
    
    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    if (displayName) {
      user.displayName = displayName;
    }
    
    await user.save();
    
    const userResponse = {
      id: user._id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt
    };
    
    res.json(userResponse);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;