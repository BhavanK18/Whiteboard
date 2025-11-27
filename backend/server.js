const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const { MongoMemoryServer } = require('mongodb-memory-server');
const Session = require('./models/session.model');

// Routes
const sessionRoutes = require('./routes/session.routes');
const whiteboardRoutes = require('./routes/whiteboard.routes');
const userRoutes = require('./routes/user.routes');
const boardRoutes = require('./routes/board.routes');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();
app.use(cors());
app.use(express.json());

// API routes
app.use('/api/sessions', sessionRoutes);
app.use('/api/whiteboards', whiteboardRoutes);
app.use('/api/users', userRoutes);
app.use('/api/board', boardRoutes);

// Default route
app.get('/', (req, res) => {
  res.json({ message: 'Whiteboard API is running' });
});

// Create HTTP server
const server = http.createServer(app);

// Socket.IO setup
const io = new Server(server, {
  cors: {
    origin: "*", // In production, restrict this to your app's domain
    methods: ["GET", "POST"]
  }
});

// Store active sessions in memory
const activeSessions = new Map();

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Join a session room - accepts both guests and logged-in users
  socket.on('join_session', async (data) => {
    const { sessionId, userName } = data;

    if (!sessionId) {
      socket.emit('join_error', { error: 'Session ID is required' });
      return;
    }

    if (!userName) {
      socket.emit('join_error', { error: 'User name is required' });
      return;
    }

    console.log(`User ${userName} (socket: ${socket.id}) joining session: ${sessionId}`);

    try {
      // Validate session exists and is active
      const session = await Session.findOne({ sessionId, isActive: true });

      if (!session) {
        socket.emit('join_error', { error: 'Invalid or expired session code' });
        return;
      }

      if (session.isExpired()) {
        socket.emit('join_error', { error: 'This session has expired' });
        return;
      }

      // Add participant to session in database if not already present
      session.addParticipant(userName);
      await session.save();

      // Store user data with the socket
      socket.userData = {
        sessionId,
        userName
      };

      // Join the room
      socket.join(sessionId);

      // Track session participants in memory
      if (!activeSessions.has(sessionId)) {
        activeSessions.set(sessionId, new Map());
      }

      activeSessions.get(sessionId).set(socket.id, {
        userName,
        joinedAt: new Date()
      });

      // Get all active participants for this session
      const participants = Array.from(activeSessions.get(sessionId).entries()).map(([id, data]) => ({
        socketId: id,
        userName: data.userName,
        joinedAt: data.joinedAt
      }));

      // Notify user of successful join
      socket.emit('join_success', {
        sessionId,
        userName,
        sessionName: session.sessionName,
        createdBy: session.createdBy,
        boardData: session.boardData,
        participants
      });

      // Notify others that a new user joined
      socket.to(sessionId).emit('user_joined', {
        userName,
        socketId: socket.id,
        count: activeSessions.get(sessionId).size,
        participants
      });

      console.log(`${userName} successfully joined session ${sessionId}`);

    } catch (error) {
      console.error(`Error joining session: ${error}`);
      socket.emit('join_error', { error: 'Failed to join session' });
    }
  });

  // Handle drawing elements
  socket.on('draw_element', (data) => {
    const { sessionId, element, pageId } = data;
    if (socket.userData?.sessionId === sessionId) {
      socket.to(sessionId).emit('draw_element', {
        element,
        pageId: pageId || 'default'
      });
    }
  });

  // Handle element updates
  socket.on('update_element', (data) => {
    const { sessionId, element, pageId } = data;
    if (socket.userData?.sessionId === sessionId) {
      socket.to(sessionId).emit('update_element', {
        element,
        pageId: pageId || 'default'
      });
    }
  });

  // Handle element deletion
  socket.on('delete_element', (data) => {
    const { sessionId, elementId, pageId } = data;
    if (socket.userData?.sessionId === sessionId) {
      socket.to(sessionId).emit('delete_element', {
        elementId,
        pageId: pageId || 'default'
      });
    }
  });

  // Handle clear board
  socket.on('clear_board', (data) => {
    const { sessionId, pageId } = data;
    if (socket.userData?.sessionId === sessionId) {
      socket.to(sessionId).emit('clear_board', {
        pageId: pageId || 'default'
      });
    }
  });

  // Handle chat messages
  socket.on('chat_message', (data) => {
    const { sessionId, message, userName } = data;
    if (socket.userData?.sessionId === sessionId) {
      io.to(sessionId).emit('chat_message', {
        userName,
        message,
        timestamp: new Date()
      });
    }
  });

  // Handle board data save
  socket.on('save_board', async (data) => {
    const { sessionId, boardData } = data;

    if (socket.userData?.sessionId === sessionId) {
      try {
        const session = await Session.findOne({ sessionId });
        if (session) {
          session.boardData = boardData;
          await session.save();
          socket.emit('save_success');
        }
      } catch (error) {
        console.error('Error saving board data:', error);
        socket.emit('save_error', { error: 'Failed to save board data' });
      }
    }
  });

  // Handle disconnection
  socket.on('disconnect', async () => {
    console.log(`Client disconnected: ${socket.id}`);

    // Get user's session from stored data
    const sessionId = socket.userData?.sessionId;
    const userName = socket.userData?.userName || 'Anonymous';

    if (sessionId && activeSessions.has(sessionId)) {
      const participants = activeSessions.get(sessionId);

      if (participants.has(socket.id)) {
        // Remove user from session participants
        participants.delete(socket.id);

        // Get updated participants list
        const updatedParticipants = Array.from(participants.entries()).map(([id, data]) => ({
          socketId: id,
          userName: data.userName,
          joinedAt: data.joinedAt
        }));

        // Notify others that a user left
        socket.to(sessionId).emit('user_left', {
          userName,
          socketId: socket.id,
          count: participants.size,
          participants: updatedParticipants
        });

        console.log(`${userName} left session ${sessionId}`);

        // Clean up empty sessions
        if (participants.size === 0) {
          activeSessions.delete(sessionId);
          console.log(`Session ${sessionId} removed from active sessions`);

          // Deactivate session in database when last user leaves
          try {
            const session = await Session.findOne({ sessionId });
            if (session && session.isActive) {
              session.isActive = false;
              await session.save();
              console.log(`Session ${sessionId} deactivated in database`);
            }
          } catch (error) {
            console.error(`Error deactivating session ${sessionId}:`, error);
          }
        }
      }
    }
  });
});

let mongoMemoryServer;

async function initializeDatabase() {
  const mongoUri = process.env.MONGODB_URI;

  if (mongoUri) {
    try {
      await mongoose.connect(mongoUri, {
        serverSelectionTimeoutMS: 5000
      });
      console.log(`Connected to MongoDB at ${mongoUri}`);
      await Session.createIndexes();
      console.log('Session indexes created');
      return;
    } catch (error) {
      console.error('MongoDB connection error:', error);
    }
  }

  console.warn('Falling back to in-memory MongoDB instance. Data will not persist after shutdown.');
  mongoMemoryServer = await MongoMemoryServer.create();
  const memoryUri = mongoMemoryServer.getUri();
  await mongoose.connect(memoryUri);
  console.log(`Connected to in-memory MongoDB at ${memoryUri}`);
  await Session.createIndexes();
  console.log('Session indexes created');
}

function startServer() {
  const PORT = process.env.PORT || 3000;
  server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Socket.IO server ready`);
  });
}

initializeDatabase()
  .then(startServer)
  .catch(error => {
    console.error('Failed to initialize database:', error);
    process.exit(1);
  });

process.on('SIGINT', async () => {
  await mongoose.disconnect();
  if (mongoMemoryServer) {
    await mongoMemoryServer.stop();
  }
  process.exit(0);
});