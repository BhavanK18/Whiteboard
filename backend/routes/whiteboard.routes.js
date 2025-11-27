const express = require('express');
const router = express.Router();
const Whiteboard = require('../models/whiteboard.model');

// Create a new whiteboard
router.post('/', async (req, res) => {
  try {
    const { name, ownerId } = req.body;
    
    if (!name || !ownerId) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    const whiteboard = new Whiteboard({
      name,
      ownerId,
      elements: []
    });
    
    await whiteboard.save();
    
    res.status(201).json(whiteboard);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get a whiteboard by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    res.json(whiteboard);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all whiteboards for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get whiteboards owned by the user
    const ownedWhiteboards = await Whiteboard.find({ ownerId: userId })
      .sort({ updatedAt: -1 });
      
    // Get whiteboards where user is a collaborator
    const collaborativeWhiteboards = await Whiteboard.find({ 
      'collaborators.userId': userId 
    }).sort({ updatedAt: -1 });
    
    res.json({
      owned: ownedWhiteboards,
      collaborative: collaborativeWhiteboards
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update a whiteboard
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    if (name) {
      whiteboard.name = name;
    }
    
    whiteboard.updatedAt = new Date();
    await whiteboard.save();
    
    res.json(whiteboard);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add or update elements in a whiteboard
router.post('/:id/elements', async (req, res) => {
  try {
    const { id } = req.params;
    const { elements, userId } = req.body;
    
    if (!Array.isArray(elements)) {
      return res.status(400).json({ message: 'Elements must be an array' });
    }
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    // For each element, check if it already exists
    for (const element of elements) {
      const existingElementIndex = whiteboard.elements.findIndex(e => e.id === element.id);
      
      // If exists, update it
      if (existingElementIndex !== -1) {
        whiteboard.elements[existingElementIndex] = {
          ...element,
          createdBy: whiteboard.elements[existingElementIndex].createdBy,
          createdAt: whiteboard.elements[existingElementIndex].createdAt
        };
      } else {
        // Otherwise add it
        whiteboard.elements.push({
          ...element,
          createdBy: userId,
          createdAt: new Date()
        });
      }
    }
    
    whiteboard.updatedAt = new Date();
    await whiteboard.save();
    
    res.json(whiteboard.elements);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete elements from a whiteboard
router.delete('/:id/elements', async (req, res) => {
  try {
    const { id } = req.params;
    const { elementIds } = req.body;
    
    if (!Array.isArray(elementIds)) {
      return res.status(400).json({ message: 'ElementIds must be an array' });
    }
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    // Remove elements by ID
    whiteboard.elements = whiteboard.elements.filter(
      element => !elementIds.includes(element.id)
    );
    
    whiteboard.updatedAt = new Date();
    await whiteboard.save();
    
    res.json({ message: 'Elements deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Clear all elements from a whiteboard
router.delete('/:id/elements/all', async (req, res) => {
  try {
    const { id } = req.params;
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    whiteboard.elements = [];
    whiteboard.updatedAt = new Date();
    await whiteboard.save();
    
    res.json({ message: 'All elements deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add a collaborator to a whiteboard
router.post('/:id/collaborators', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, role } = req.body;
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    // Check if collaborator already exists
    const existingCollaborator = whiteboard.collaborators.find(
      c => c.userId.toString() === userId
    );
    
    if (existingCollaborator) {
      existingCollaborator.role = role || existingCollaborator.role;
    } else {
      whiteboard.collaborators.push({
        userId,
        role: role || 'viewer'
      });
    }
    
    whiteboard.updatedAt = new Date();
    await whiteboard.save();
    
    res.json(whiteboard.collaborators);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Remove a collaborator from a whiteboard
router.delete('/:id/collaborators/:userId', async (req, res) => {
  try {
    const { id, userId } = req.params;
    
    const whiteboard = await Whiteboard.findById(id);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    whiteboard.collaborators = whiteboard.collaborators.filter(
      c => c.userId.toString() !== userId
    );
    
    whiteboard.updatedAt = new Date();
    await whiteboard.save();
    
    res.json({ message: 'Collaborator removed successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;