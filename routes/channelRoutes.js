const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET ALL CHANNELS
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM channels ORDER BY id DESC'
    );

    res.json({
      success: true,
      channels: result.rows,
    });
  } catch (error) {
    console.error('Error fetching channels:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

module.exports = router;