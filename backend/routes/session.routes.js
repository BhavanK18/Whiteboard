const express = require('express');
const router = express.Router();
const Session = require('../models/session.model');
const { v4: uuidv4 } = require('uuid');

// Helper to generate guest username
function createGuestUser() {
  return 'Guest' + Math.floor(1000 + Math.random() * 9000);
}

// Helper to generate unique 8-character session code
function generateSessionCode() {
  return uuidv4().slice(0, 8).toUpperCase();
}

// Create a new session
router.post('/create', async (req, res) => {
  try {
    const { sessionName, userId } = req.body;

    if (!sessionName || sessionName.trim().length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Session name is required' 
      });
    }

    // Determine creator (use userId if provided, otherwise create guest)
    const createdBy = userId || createGuestUser();
    const userRole = userId ? 'owner' : 'guest';

    // Check for existing session with same name by this user
    const existingSession = await Session.findOne({ 
      sessionName: sessionName.trim(), 
      createdBy
    });

    // If there's an active session with same name, return error
    if (existingSession && existingSession.isActive) {
      return res.status(409).json({ 
        success: false, 
        error: 'You already have an active session with this name',
        sessionId: existingSession.sessionId,
        sessionCode: existingSession.sessionCode
      });
    }

    // If there's an inactive session, reactivate it instead of creating new one
    if (existingSession && !existingSession.isActive) {
      existingSession.isActive = true;
      existingSession.expiresAt = new Date(+new Date() + 7*24*60*60*1000);
      existingSession.participants = [createdBy];
      existingSession.boardData = { elements: [], backgroundColor: '#ffffff' };
      await existingSession.save();

      return res.status(200).json({
        success: true,
        sessionId: existingSession.sessionId,
        sessionCode: existingSession.sessionCode,
        inviteLink: existingSession.inviteLink,
        userRole,
        createdBy: existingSession.createdBy,
        sessionName: existingSession.sessionName,
        createdAt: existingSession.createdAt,
        reactivated: true
      });
    }

    // Generate unique session code
    let sessionCode = generateSessionCode();
    let codeExists = await Session.findOne({ sessionCode });
    
    while (codeExists) {
      sessionCode = generateSessionCode();
      codeExists = await Session.findOne({ sessionCode });
    }

    // Create invite link
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const inviteLink = `${baseUrl}/join/${sessionCode}`;

    // Create new session
    const session = new Session({
      sessionName: sessionName.trim(),
      createdBy,
      sessionCode,
      inviteLink,
      participants: [createdBy]
    });

    await session.save();

    return res.status(201).json({
      success: true,
      sessionId: session.sessionId,
      sessionCode: session.sessionCode,
      inviteLink: session.inviteLink,
      userRole,
      createdBy: session.createdBy,
      sessionName: session.sessionName,
      createdAt: session.createdAt
    });

  } catch (error) {
    console.error('Error creating session:', error);
    
    // Handle duplicate key errors
    if (error.code === 11000) {
      return res.status(409).json({ 
        success: false, 
        error: 'A session with this name already exists' 
      });
    }
    
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to create session' 
    });
  }
});

// Join a session by session code
router.post('/join', async (req, res) => {
  try {
    const { sessionCode, userId } = req.body;

    if (!sessionCode || sessionCode.trim().length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Session code is required' 
      });
    }

    // Find session by code
    const session = await Session.findOne({ 
      sessionCode: sessionCode.trim().toUpperCase(),
      isActive: true 
    });

    if (!session) {
      return res.status(404).json({ 
        success: false, 
        error: 'Invalid or expired session code' 
      });
    }

    // Check if session is expired
    if (session.isExpired()) {
      return res.status(404).json({ 
        success: false, 
        error: 'This session has expired' 
      });
    }

    // Determine participant name
    const userName = userId || createGuestUser();
    const userRole = (session.createdBy === userName) ? 'owner' : (userId ? 'participant' : 'guest');

    // Add participant if not already in the list
    session.addParticipant(userName);
    await session.save();

    return res.json({
      success: true,
      sessionId: session.sessionId,
      sessionCode: session.sessionCode,
      inviteLink: session.inviteLink,
      userRole,
      createdBy: session.createdBy,
      sessionName: session.sessionName,
      boardData: session.boardData,
      participants: session.participants,
      userName
    });

  } catch (error) {
    console.error('Error joining session:', error);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to join session' 
    });
  }
});

// Get session by sessionId
router.get('/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    const session = await Session.findOne({ sessionId, isActive: true });

    if (!session) {
      return res.status(404).json({ 
        success: false, 
        error: 'Session not found' 
      });
    }

    if (session.isExpired()) {
      return res.status(404).json({ 
        success: false, 
        error: 'This session has expired' 
      });
    }

    return res.json({
      success: true,
      sessionId: session.sessionId,
      sessionCode: session.sessionCode,
      sessionName: session.sessionName,
      createdBy: session.createdBy,
      createdAt: session.createdAt,
      participants: session.participants,
      boardData: session.boardData,
      inviteLink: session.inviteLink
    });

  } catch (error) {
    console.error('Error getting session:', error);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to get session' 
    });
  }
});

// Get all sessions for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const sessions = await Session.find({ 
      createdBy: userId,
      isActive: true,
      expiresAt: { $gt: new Date() }
    })
    .sort({ createdAt: -1 });

    return res.json({
      success: true,
      sessions: sessions.map(s => ({
        sessionId: s.sessionId,
        sessionCode: s.sessionCode,
        sessionName: s.sessionName,
        createdBy: s.createdBy,
        createdAt: s.createdAt,
        participants: s.participants,
        inviteLink: s.inviteLink
      }))
    });

  } catch (error) {
    console.error('Error getting user sessions:', error);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to get sessions' 
    });
  }
});

// Update session board data
router.put('/:sessionId/board', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { boardData } = req.body;

    const session = await Session.findOne({ sessionId, isActive: true });

    if (!session) {
      return res.status(404).json({ 
        success: false, 
        error: 'Session not found' 
      });
    }

    session.boardData = boardData;
    await session.save();

    return res.json({
      success: true,
      boardData: session.boardData
    });

  } catch (error) {
    console.error('Error updating board data:', error);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to update board data' 
    });
  }
});

// Delete a session
router.delete('/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { userId } = req.body;

    const session = await Session.findOne({ sessionId });

    if (!session) {
      return res.status(404).json({ 
        success: false, 
        error: 'Session not found' 
      });
    }

    // Only allow owner to delete
    if (session.createdBy !== userId) {
      return res.status(403).json({ 
        success: false, 
        error: 'Only the session owner can delete this session' 
      });
    }

    session.isActive = false;
    await session.save();

    return res.json({
      success: true,
      message: 'Session deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting session:', error);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to delete session' 
    });
  }
});

// Deactivate a session (called on close/disconnect)
router.put('/:sessionId/deactivate', async (req, res) => {
  try {
    const { sessionId } = req.params;

    const session = await Session.findOne({ sessionId });

    if (!session) {
      return res.status(404).json({ 
        success: false, 
        error: 'Session not found' 
      });
    }

    session.isActive = false;
    await session.save();

    return res.json({
      success: true,
      message: 'Session deactivated successfully'
    });

  } catch (error) {
    console.error('Error deactivating session:', error);
    return res.status(500).json({ 
      success: false, 
      error: 'Failed to deactivate session' 
    });
  }
});

module.exports = router;