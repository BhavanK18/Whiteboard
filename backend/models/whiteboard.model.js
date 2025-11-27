const mongoose = require('mongoose');

const drawElementSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true
  },
  type: {
    type: String,
    required: true,
    enum: ['pen', 'line', 'rectangle', 'circle', 'text', 'eraser']
  },
  points: [{
    x: Number,
    y: Number,
    color: Number,
    strokeWidth: Number,
    isAntiAlias: Boolean
  }],
  color: Number,
  strokeWidth: Number,
  text: String,
  fontSize: Number,
  position: {
    x: Number,
    y: Number
  },
  size: {
    width: Number,
    height: Number
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const whiteboardSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  collaborators: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    role: {
      type: String,
      enum: ['viewer', 'editor'],
      default: 'viewer'
    },
    addedAt: {
      type: Date,
      default: Date.now
    }
  }],
  elements: [drawElementSchema],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Whiteboard', whiteboardSchema);