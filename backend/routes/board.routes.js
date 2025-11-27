const express = require('express');
const router = express.Router();
const Session = require('../models/session.model');
const Whiteboard = require('../models/whiteboard.model');

// Get board state by session ID
router.get('/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    
    // Find the session by ID
    const session = await Session.findById(sessionId);
    
    if (!session) {
      return res.status(404).json({ message: 'Session not found' });
    }
    
    // Get the associated whiteboard
    const whiteboard = await Whiteboard.findById(session.whiteboardId);
    
    if (!whiteboard) {
      return res.status(404).json({ message: 'Whiteboard not found' });
    }
    
    res.json({
      session: {
        id: session._id,
        code: session.code,
        name: session.name,
        isPublic: session.isPublic,
        ownerId: session.ownerId,
        participants: session.participants || []
      },
      whiteboard: {
        id: whiteboard._id,
        name: whiteboard.name,
        elements: whiteboard.elements || [],
        ownerId: whiteboard.ownerId,
        createdAt: whiteboard.createdAt,
        updatedAt: whiteboard.updatedAt
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;