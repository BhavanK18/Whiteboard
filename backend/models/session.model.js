const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const sessionSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    unique: true,
    default: () => uuidv4(),
    required: true
  },
  sessionCode: {
    type: String,
    unique: true,
    required: true,
    index: true
  },
  sessionName: {
    type: String,
    required: true,
    trim: true
  },
  createdBy: {
    type: String,
    required: true,
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  participants: [{
    type: String
  }],
  boardData: {
    type: mongoose.Schema.Types.Mixed,
    default: {
      elements: [],
      backgroundColor: '#ffffff'
    }
  },
  inviteLink: {
    type: String
  },
  isActive: {
    type: Boolean,
    default: true
  },
  expiresAt: {
    type: Date,
    default: () => new Date(+new Date() + 7*24*60*60*1000) // 7 days from now
  }
});

// Compound index to prevent duplicate ACTIVE session names per user
// Allow duplicate names if at least one is inactive
sessionSchema.index({ sessionName: 1, createdBy: 1, isActive: 1 }, { 
  unique: true,
  partialFilterExpression: { isActive: true }
});

// Instance method to add a participant
sessionSchema.methods.addParticipant = function(userName) {
  if (!this.participants.includes(userName)) {
    this.participants.push(userName);
  }
  return this;
};

// Instance method to check if session is expired
sessionSchema.methods.isExpired = function() {
  return this.expiresAt < new Date() || !this.isActive;
};

module.exports = mongoose.model('Session', sessionSchema);